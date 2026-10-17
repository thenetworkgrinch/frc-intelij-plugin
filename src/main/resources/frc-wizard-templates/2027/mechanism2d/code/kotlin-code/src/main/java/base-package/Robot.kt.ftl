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
package [=data.basePackage]

import org.wpilib.drivers.motor.PWMSparkMax
import org.wpilib.driverstation.Joystick
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.hardware.rotation.AnalogPotentiometer
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.smartdashboard.Mechanism2d
import org.wpilib.smartdashboard.MechanismLigament2d
import org.wpilib.smartdashboard.MechanismRoot2d
import org.wpilib.telemetry.Telemetry
import org.wpilib.util.Color
import org.wpilib.util.Color8Bit

/**
 * This sample program shows how to use Mechanism2d - a visual representation of arms, elevators,
 * and other mechanisms on dashboards; driven by a node-based API.
 *
 * Ligaments are based on other ligaments or roots, and roots are contained in the base
 * Mechanism2d object.
 *
 * This is written as an object rather than a class since there should only ever be a single
 * robot instance. If you change the name of this object or its package after creating this
 * project, you must also update the `Main.kt` file in the project.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private const val METERS_PER_PULSE = 0.01
    private const val ELEVATOR_MINIMUM_LENGTH = 0.5

    private val elevatorMotor = PWMSparkMax(0)
    private val wristMotor = PWMSparkMax(1)
    private val wristPot = AnalogPotentiometer(1, 90.0)
    private val elevatorEncoder = Encoder(0, 1)
    private val joystick = Joystick(0)

    // the main mechanism object
    private val mech = Mechanism2d(3.0, 3.0)
    private val elevator: MechanismLigament2d
    private val wrist: MechanismLigament2d

    /** Called once at the beginning of the robot program. */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        elevatorEncoder.setDistancePerPulse(METERS_PER_PULSE)

        // the mechanism root node
        val root: MechanismRoot2d = mech.getRoot("climber", 2.0, 0.0)

        // MechanismLigament2d objects represent each "section"/"stage" of the mechanism, and are based
        // off the root node or another ligament object
        elevator = root.append(MechanismLigament2d("elevator", ELEVATOR_MINIMUM_LENGTH, 90.0))
        wrist = elevator.append(MechanismLigament2d("wrist", 0.5, 90.0, 6.0, Color8Bit(Color.PURPLE)))
    }

    override fun robotPeriodic()
    {
        // update the dashboard mechanism's state
        elevator.setLength(ELEVATOR_MINIMUM_LENGTH + elevatorEncoder.distance)
        wrist.setAngle(wristPot.get())

        // post the mechanism to telemetry
        Telemetry.log("Mech2d", mech)
    }

    override fun teleopPeriodic()
    {
        elevatorMotor.setThrottle(joystick.getRawAxis(0))
        wristMotor.setThrottle(joystick.getRawAxis(1))
    }
}
