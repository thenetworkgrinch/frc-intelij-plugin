<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This template uses alternate square bracket interpolation syntax
               For example:
                    [=data.robotClassSimpleName]
               rather than:
                    ${data.robotClassSimpleName}
               so as to not clash with Kotlin string templates syntax
               The option to use that can't be set in the template, but has to be set as an
               option on the Configuration object in the code. Note that this only affects interpolation
               syntax, and *NOT* Tag syntax. So we will still use `<#if isSuchAndSuch>` and not `[#if isSuchAndSuch]`.
               Tag syntax can be changed if desired, but we are not.
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
package [=data.basePackage].subsystems

import [=data.basePackage].Constants
import org.wpilib.drivers.motor.PWMSparkMax
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.math.controller.PIDController
import org.wpilib.math.system.DCMotor
import org.wpilib.math.util.Units
import org.wpilib.preferences.Preferences
import org.wpilib.simulation.BatterySim
import org.wpilib.simulation.EncoderSim
import org.wpilib.simulation.RoboRioSim
import org.wpilib.simulation.SingleJointedArmSim
import org.wpilib.smartdashboard.Mechanism2d
import org.wpilib.smartdashboard.MechanismLigament2d
import org.wpilib.smartdashboard.MechanismRoot2d
import org.wpilib.system.RobotController
import org.wpilib.telemetry.Telemetry
import org.wpilib.util.Color
import org.wpilib.util.Color8Bit

class Arm : AutoCloseable
{
    // The P gain for the PID controller that drives this arm.
    private var armKp = Constants.DEFAULT_ARM_KP
    private var armSetpointDegrees = Constants.DEFAULT_ARM_SETPOINT_DEGREES

    // The arm gearbox represents a gearbox containing two Vex 775pro motors.
    private val armGearbox = DCMotor.getVex775Pro(2)

    // Standard classes for controlling our arm
    private val controller = PIDController(armKp, 0.0, 0.0)
    private val encoder = Encoder(Constants.ENCODER_A_CHANNEL, Constants.ENCODER_B_CHANNEL)
    private val motor = PWMSparkMax(Constants.MOTOR_PORT)

    // Simulation classes help us simulate what's going on, including gravity.
    // This arm sim represents an arm that can travel from -75 degrees (rotated down front)
    // to 255 degrees (rotated down in the back).
    private val armSim = SingleJointedArmSim(
        armGearbox,
        Constants.ARM_REDUCTION,
        SingleJointedArmSim.estimateMOI(Constants.ARM_LENGTH, Constants.ARM_MASS),
        Constants.ARM_LENGTH,
        Constants.MIN_ANGLE_RADS,
        Constants.MAX_ANGLE_RADS,
        true,
        0.0,
        Constants.ARM_ENCODER_DIST_PER_PULSE,
        0.0 // Add noise with a std-dev of 1 tick
    )
    private val encoderSim = EncoderSim(encoder)

    // Create a Mechanism2d display of an Arm with a fixed ArmTower and moving Arm.
    private val mech2d = Mechanism2d(60.0, 60.0)
    private val armPivot: MechanismRoot2d = mech2d.getRoot("ArmPivot", 30.0, 30.0)
    private val armTower: MechanismLigament2d = armPivot.append(MechanismLigament2d("ArmTower", 30.0, -90.0))
    private val arm: MechanismLigament2d = armPivot.append(
        MechanismLigament2d(
            "Arm",
            30.0,
            Units.radiansToDegrees(armSim.angle),
            6.0,
            Color8Bit(Color.YELLOW)
        )
    )

    /** Subsystem constructor. */
    init
    {
        encoder.setDistancePerPulse(Constants.ARM_ENCODER_DIST_PER_PULSE)

        armTower.setColor(Color8Bit(Color.BLUE))

        // Set the Arm position setpoint and P constant to Preferences if the keys don't already exist
        Preferences.initDouble(Constants.ARM_POSITION_KEY, armSetpointDegrees)
        Preferences.initDouble(Constants.ARM_P_KEY, armKp)
    }

    /** Update the simulation model. */
    fun simulationPeriodic()
    {
        // In this method, we update our simulation of what our arm is doing
        // First, we set our "inputs" (voltages)
        armSim.setInput(motor.throttle * RobotController.getBatteryVoltage())

        // Next, we update it. The standard loop time is 20ms.
        armSim.update(0.020)

        // Finally, we set our simulated encoder's readings and simulated battery voltage
        encoderSim.setDistance(armSim.angle)
        // SimBattery estimates loaded battery voltages
        RoboRioSim.setVInVoltage(BatterySim.calculateDefaultBatteryLoadedVoltage(armSim.currentDraw))

        // Update the Mechanism Arm angle based on the simulated arm angle
        arm.setAngle(Units.radiansToDegrees(armSim.angle))

        // Put Mechanism 2d to SmartDashboard
        Telemetry.log("Arm Sim", mech2d)
    }

    /** Load setpoint and kP from preferences. */
    fun loadPreferences()
    {
        // Read Preferences for Arm setpoint and kP on entering Teleop
        armSetpointDegrees = Preferences.getDouble(Constants.ARM_POSITION_KEY, armSetpointDegrees)
        if (armKp != Preferences.getDouble(Constants.ARM_P_KEY, armKp))
        {
            armKp = Preferences.getDouble(Constants.ARM_P_KEY, armKp)
            controller.p = armKp
        }
    }

    /** Run the control loop to reach and maintain the setpoint from the preferences. */
    fun reachSetpoint()
    {
        val pidOutput = controller.calculate(encoder.distance, Units.degreesToRadians(armSetpointDegrees))
        motor.setVoltage(pidOutput)
    }

    fun stop()
    {
        motor.throttle = 0.0
    }

    override fun close()
    {
        motor.close()
        encoder.close()
    }
}
