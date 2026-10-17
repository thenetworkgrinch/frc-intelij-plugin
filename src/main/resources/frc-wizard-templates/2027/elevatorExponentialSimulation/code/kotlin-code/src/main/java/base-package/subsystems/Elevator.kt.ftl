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
import org.wpilib.math.controller.ElevatorFeedforward
import org.wpilib.math.controller.PIDController
import org.wpilib.math.system.DCMotor
import org.wpilib.math.trajectory.ExponentialProfile
import org.wpilib.math.util.Units
import org.wpilib.simulation.BatterySim
import org.wpilib.simulation.ElevatorSim
import org.wpilib.simulation.EncoderSim
import org.wpilib.simulation.PWMMotorControllerSim
import org.wpilib.simulation.RoboRioSim
import org.wpilib.smartdashboard.Mechanism2d
import org.wpilib.smartdashboard.MechanismLigament2d
import org.wpilib.smartdashboard.MechanismRoot2d
import org.wpilib.system.RobotController
import org.wpilib.telemetry.Telemetry

class Elevator : AutoCloseable
{
    // This gearbox represents a gearbox containing 4 Vex 775pro motors.
    private val elevatorGearbox = DCMotor.getNEO(2)

    private val profile = ExponentialProfile(
        ExponentialProfile.Constraints.fromCharacteristics(
            Constants.ELEVATOR_MAX_V, Constants.ELEVATOR_KV, Constants.ELEVATOR_KA
        )
    )

    private var setpoint = ExponentialProfile.State(0.0, 0.0)

    // Standard classes for controlling our elevator
    private val pidController = PIDController(Constants.ELEVATOR_KP, Constants.ELEVATOR_KI, Constants.ELEVATOR_KD)

    private val feedforward = ElevatorFeedforward(
        Constants.ELEVATOR_KS,
        Constants.ELEVATOR_KG,
        Constants.ELEVATOR_KV,
        Constants.ELEVATOR_KA
    )
    private val encoder = Encoder(Constants.ENCODER_A_CHANNEL, Constants.ENCODER_B_CHANNEL)
    private val motor = PWMSparkMax(Constants.MOTOR_PORT)

    // Simulation classes help us simulate what's going on, including gravity.
    private val elevatorSim = ElevatorSim(
        elevatorGearbox,
        Constants.ELEVATOR_GEARING,
        Constants.CARRIAGE_MASS,
        Constants.ELEVATOR_DRUM_RADIUS,
        Constants.MIN_ELEVATOR_HEIGHT,
        Constants.MAX_ELEVATOR_HEIGHT,
        true,
        0.0,
        0.005,
        0.0
    )
    private val encoderSim = EncoderSim(encoder)
    private val motorSim = PWMMotorControllerSim(motor)

    // Create a Mechanism2d visualization of the elevator
    private val mech2d = Mechanism2d(Units.inchesToMeters(10.0), Units.inchesToMeters(51.0))
    private val mech2dRoot: MechanismRoot2d =
        mech2d.getRoot("Elevator Root", Units.inchesToMeters(5.0), Units.inchesToMeters(0.5))
    private val elevatorMech2d: MechanismLigament2d =
        mech2dRoot.append(MechanismLigament2d("Elevator", elevatorSim.position, 90.0))

    /** Subsystem constructor. */
    init
    {
        encoder.setDistancePerPulse(Constants.ELEVATOR_ENCODER_DIST_PER_PULSE)
    }

    /** Advance the simulation. */
    fun simulationPeriodic()
    {
        // In this method, we update our simulation of what our elevator is doing
        // First, we set our "inputs" (voltages)
        elevatorSim.setInput(motorSim.throttle * RobotController.getBatteryVoltage())

        // Next, we update it. The standard loop time is 20ms.
        elevatorSim.update(0.020)

        // Finally, we set our simulated encoder's readings and simulated battery voltage
        encoderSim.setDistance(elevatorSim.position)
        // SimBattery estimates loaded battery voltages
        RoboRioSim.setVInVoltage(BatterySim.calculateDefaultBatteryLoadedVoltage(elevatorSim.currentDraw))
    }

    /**
     * Run control loop to reach and maintain goal.
     *
     * @param goal the position to maintain
     */
    fun reachGoal(goal: Double)
    {
        val goalState = ExponentialProfile.State(goal, 0.0)

        val next = profile.calculate(0.020, setpoint, goalState)

        // With the setpoint value we run PID control like normal
        val pidOutput = pidController.calculate(encoder.distance, setpoint.position)
        val feedforwardOutput = feedforward.calculate(setpoint.velocity, next.velocity)

        motor.setVoltage(pidOutput + feedforwardOutput)

        setpoint = next
    }

    /** Stop the control loop and motor output. */
    fun stop()
    {
        motor.throttle = 0.0
    }

    /** Reset Exponential profile to begin from current position on enable. */
    fun reset()
    {
        setpoint = ExponentialProfile.State(encoder.distance, 0.0)
    }

    /** Update telemetry, including the mechanism visualization. */
    fun updateTelemetry()
    {
        // Update elevator visualization with position
        elevatorMech2d.setLength(encoder.distance)

        // Publish Mechanism2d to telemetry
        // To view the Elevator visualization, select Network Tables -> Telemetry -> Elevator Sim
        Telemetry.log("Elevator Sim", mech2d)
    }

    override fun close()
    {
        encoder.close()
        motor.close()
    }
}
