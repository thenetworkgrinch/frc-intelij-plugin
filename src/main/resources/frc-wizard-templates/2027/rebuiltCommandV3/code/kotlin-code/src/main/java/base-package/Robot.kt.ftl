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

import [=data.basePackage].constants.FieldConstants.NEUTRAL_ZONE
import org.wpilib.units.Units.Meters

import org.wpilib.command3.Command
import org.wpilib.command3.Scheduler
import org.wpilib.command3.Trigger
import org.wpilib.command3.button.CommandGamepad
import org.wpilib.epilogue.Epilogue
import org.wpilib.epilogue.Logged
import [=data.basePackage].mechanisms.Intake
import [=data.basePackage].mechanisms.Shooter
import [=data.basePackage].mechanisms.SwerveDrive
import org.wpilib.framework.OpModeRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.math.geometry.Pose2d

/**
 * The robot. This is written as an object rather than a class since there should only ever be a
 * single robot instance. If you change the name of this object or its package after creating this
 * project, you must also update the `Main.kt` file in the project.
 *
 * The op modes in the `opmodes` packages receive this object in their constructors and use its
 * mechanisms.
 */
@Logged
object [=data.robotClassSimpleName] : OpModeRobot()
{
    // Epilogue logs instance fields and public getters, but not static fields. A Kotlin object keeps
    // its properties in static fields, so the properties to log are public and are logged through
    // their getters, under the same names a Java Robot class's fields would have.
    @get:Logged(name = "swerveDrive")
    val swerveDrive = SwerveDrive()
    @get:Logged(name = "shooter")
    val shooter = Shooter()
    @get:Logged(name = "intake")
    val intake = Intake()
    @get:Logged(name = "poseEstimator")
    val poseEstimator = PoseEstimator()
    val controller = CommandGamepad(1)

    @get:Logged(name = "inNeutralZone")
    val inNeutralZone = Trigger { poseEstimator.inZone(NEUTRAL_ZONE) }

    // Store the scheduler in a property for Epilogue to pick up and log for us. (It is public, where a
    // Java robot class could keep it private, because Epilogue logs a Kotlin object's properties only
    // through their public getters.)
    @get:Logged(name = "scheduler")
    val scheduler: Scheduler = Scheduler.getDefault()

    /** Initializes the robot object and sets safe default commands for all its mechanisms. */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        swerveDrive.setDefaultCommand(swerveDrive.idle())
        shooter.setDefaultCommand(shooter.idle())
        intake.setDefaultCommand(intake.idle())
    }

    override fun robotPeriodic()
    {
        // 1. Update odometry so commands will be working with up-to-date information.
        poseEstimator.odometryUpdate(swerveDrive.gyroHeading, *swerveDrive.modulePositions)

        // 2. Run the scheduler to poll triggers and execute our commands.
        scheduler.run()

        // 3. Update telemetry.
        Epilogue.update(this)
    }

    /**
     * A command that uses all the mechanisms on the robot to aim and shoot at a specific target.
     *
     * @param targetPose The target position to shoot at.
     * @return A command to shoot at a target
     */
    fun shootAt(targetPose: Pose2d): Command
    {
        return Command.noRequirements { coroutine ->
            coroutine.await(swerveDrive.aimAt({ poseEstimator.estimatedPose }, targetPose))

            coroutine.awaitAll(
                intake.agitate(),
                shooter.shootAtHub {
                    Meters.of(
                        targetPose
                            .minus(poseEstimator.estimatedPose)
                            .translation
                            .norm)
                })
        }
            .named("Robot.ShootAt[$targetPose]")
    }
}
