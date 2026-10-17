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
package [=data.basePackage].opmodes.auto

import org.wpilib.command3.Command
import org.wpilib.command3.Trigger
import org.wpilib.driverstation.RobotState
import [=data.basePackage].[=data.robotClassSimpleName]
import [=data.basePackage].constants.FieldConstants
import org.wpilib.opmode.Autonomous
import org.wpilib.opmode.OpMode

/**
 * Creates a new autonomous mode that sweeps the left trench and scores on the hub. This
 * constructor is called automatically by the OpModeRobot framework when the program starts up.
 *
 * @param robot The robot instance to control.
 */
@Autonomous
class SweepAuto(robot: [=data.robotClassSimpleName]) : OpMode
{
    private val enabled = Trigger(RobotState::isEnabled)

    init
    {
        // Start the intake stowed
        robot.intake.setDefaultCommand(robot.intake.stow())

        // Extend the intake once we cross into the neutral zone and leave it extended for the entire
        // opmode
        robot.inNeutralZone.onTrue(robot.intake.intake())

        // Once the robot is enabled, start following a sweep path through the left trench,
        // into the neutral zone, then back over the bump.
        // When we return to the alliance zone, aim at the hub and start shooting.
        enabled.onTrue(sweepAndScore(robot))
    }

    /**
     * Creates a command that drives the robot in a path that sweeps through the neutral zone to
     * gather fuel, returns to the alliance zone, and then shoots at the hub until the end of the
     * autonomous period.
     *
     * @param robot The robot instance to control
     * @return A sweep-and-score command
     */
    private fun sweepAndScore(robot: [=data.robotClassSimpleName]): Command
    {
        return Command.noRequirements { coroutine ->
            coroutine.await(robot.swerveDrive.followPath("nz-sweep-left-trench"))

            FieldConstants.targetHub()
                .ifPresent { hub ->
                    coroutine.await(robot.shootAt(hub))
                }
        }
            .named("Sweep and Score")
    }
}
