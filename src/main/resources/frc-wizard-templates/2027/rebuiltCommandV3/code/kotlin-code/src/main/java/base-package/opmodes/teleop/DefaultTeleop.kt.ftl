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
package [=data.basePackage].opmodes.teleop

import [=data.basePackage].[=data.robotClassSimpleName]
import [=data.basePackage].constants.FieldConstants
import org.wpilib.opmode.OpMode
import org.wpilib.opmode.Teleop

/**
 * Creates a new default teleop mode. This constructor is called automatically by the OpModeRobot
 * framework when the program starts up.
 *
 * @param robot The robot instance to control.
 */
@Teleop
class DefaultTeleop(robot: [=data.robotClassSimpleName]) : OpMode
{
    init
    {
        robot.swerveDrive.setDefaultCommand(robot.swerveDrive.driverControl(robot.controller))

        robot.controller.faceUp().onTrue(robot.intake.intake())
        robot.controller.faceDown().onTrue(robot.intake.stow())
        robot.controller.faceRight().whileTrue(robot.intake.agitate())

        // The right stick is used for turning, but switch to aim assist when the driver presses down
        // on the stick. Un-pressing the stick will return to normal driver control.
        // If, for some reason, no target hub is found, the robot's current pose will be used as the
        // target location.
        robot
            .controller
            .rightStick()
            .whileTrue(
                robot.swerveDrive.aimAssist(
                    robot.controller,
                    { robot.poseEstimator.estimatedPose },
                    { FieldConstants.targetHub().orElseGet { robot.poseEstimator.estimatedPose } }))
    }
}
