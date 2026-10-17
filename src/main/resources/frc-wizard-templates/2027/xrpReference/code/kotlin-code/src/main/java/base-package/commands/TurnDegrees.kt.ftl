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
package [=data.basePackage].commands

import org.wpilib.command2.Command
import [=data.basePackage].subsystems.Drivetrain
import kotlin.math.PI
import kotlin.math.abs

/**
 * Creates a new TurnDegrees. This command will turn your robot for a desired rotation (in
 * degrees) and rotational velocity.
 *
 * @param velocity The velocity which the robot will drive. Negative is in reverse.
 * @param degrees Degrees to turn. Leverages encoders to compare distance.
 * @param drive The drive subsystem on which this command will run
 */
class TurnDegrees(private val velocity: Double, private val degrees: Double, private val drive: Drivetrain) : Command()
{
    init
    {
        addRequirements(drive)
    }

    // Called when the command is initially scheduled.
    override fun initialize()
    {
        // Set motors to stop, read encoder values for starting point
        drive.arcadeDrive(0.0, 0.0)
        drive.resetEncoders()
    }

    // Called every time the scheduler runs while the command is scheduled.
    override fun execute()
    {
        drive.arcadeDrive(0.0, velocity)
    }

    // Called once the command ends or is interrupted.
    override fun end(interrupted: Boolean)
    {
        drive.arcadeDrive(0.0, 0.0)
    }

    // Returns true when the command should end.
    override fun isFinished(): Boolean
    {
        /* Need to convert distance travelled to degrees. The Standard
           XRP Chassis found here, https://www.sparkfun.com/products/22230,
           has a wheel placement diameter (163 mm) - width of the wheel (8 mm) = 155 mm
           or 6.102 inches. We then take into consideration the width of the tires.
        */
        val inchPerDegree = PI * 6.102 / 360
        // Compare distance travelled from start to distance based on degree turn
        return averageTurningDistance >= (inchPerDegree * degrees)
    }

    private val averageTurningDistance: Double
        get()
        {
            val leftDistance = abs(drive.leftDistanceInch)
            val rightDistance = abs(drive.rightDistanceInch)
            return (leftDistance + rightDistance) / 2.0
        }
}
