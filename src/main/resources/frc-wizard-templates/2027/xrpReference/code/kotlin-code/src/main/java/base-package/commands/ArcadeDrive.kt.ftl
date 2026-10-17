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

/**
 * Creates a new ArcadeDrive. This command will drive your robot according to the velocity
 * supplier lambdas. This command does not terminate.
 *
 * @param drivetrain The drivetrain subsystem on which this command will run
 * @param xaxisVelocitySupplier Lambda supplier of forward/backward velocity
 * @param zaxisRotateSupplier Lambda supplier of rotational velocity
 */
class ArcadeDrive(
    private val drivetrain: Drivetrain,
    private val xaxisVelocitySupplier: () -> Double,
    private val zaxisRotateSupplier: () -> Double,
                 ) : Command()
{
    init
    {
        addRequirements(drivetrain)
    }

    // Called when the command is initially scheduled.
    override fun initialize() {}

    // Called every time the scheduler runs while the command is scheduled.
    override fun execute()
    {
        drivetrain.arcadeDrive(xaxisVelocitySupplier(), zaxisRotateSupplier())
    }

    // Called once the command ends or is interrupted.
    override fun end(interrupted: Boolean) {}

    // Returns true when the command should end.
    override fun isFinished(): Boolean = false
}
