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
package [=data.basePackage].mechanisms

import org.wpilib.epilogue.Logged
import org.wpilib.epilogue.NotLogged
import org.wpilib.units.Units.MetersPerSecond
import org.wpilib.units.Units.Radians
import org.wpilib.units.Units.RadiansPerSecond

import kotlin.math.PI
import kotlin.math.atan2
import org.wpilib.command3.Command
import org.wpilib.command3.Mechanism
import org.wpilib.command3.button.CommandGamepad
import [=data.basePackage].constants.DriveConstants
import [=data.basePackage].stubs.ExampleSmartMotorController
import [=data.basePackage].stubs.PathFollower
import org.wpilib.hardware.imu.OnboardIMU
import org.wpilib.math.controller.PIDController
import org.wpilib.math.geometry.Pose2d
import org.wpilib.math.geometry.Rotation2d
import org.wpilib.math.kinematics.ChassisVelocities
import org.wpilib.math.kinematics.SwerveDriveKinematics
import org.wpilib.math.kinematics.SwerveModulePosition
import org.wpilib.math.kinematics.SwerveModuleVelocity
import org.wpilib.units.measure.Angle
import org.wpilib.units.measure.AngularVelocity

@Logged
class SwerveDrive : Mechanism
{
    // Logged through its field, as in Java; @get:NotLogged keeps Epilogue from logging the getter too
    @get:NotLogged
    val kinematics: SwerveDriveKinematics = DriveConstants.KINEMATICS
    private val gyro = OnboardIMU(OnboardIMU.MountOrientation.FLAT)
    private val frontLeft = SwerveModule(
        ExampleSmartMotorController(DriveConstants.FRONT_LEFT_DRIVE_ID),
        ExampleSmartMotorController(DriveConstants.FRONT_LEFT_TURN_ID))
    private val frontRight = SwerveModule(
        ExampleSmartMotorController(DriveConstants.FRONT_RIGHT_DRIVE_ID),
        ExampleSmartMotorController(DriveConstants.FRONT_RIGHT_TURN_ID))
    private val rearLeft = SwerveModule(
        ExampleSmartMotorController(DriveConstants.REAR_LEFT_DRIVE_ID),
        ExampleSmartMotorController(DriveConstants.REAR_LEFT_TURN_ID))
    private val rearRight = SwerveModule(
        ExampleSmartMotorController(DriveConstants.REAR_RIGHT_DRIVE_ID),
        ExampleSmartMotorController(DriveConstants.REAR_RIGHT_TURN_ID))

    // PID controllers for XY field position and heading
    // These accept position (meters for XY, radians for heading) and output velocities
    // (meters per second for XY, radians per second for heading)
    private val xController = PIDController(0.05, 0.0, 0.0)
    private val yController = PIDController(0.05, 0.0, 0.0)
    private val headingController = PIDController(0.05, 0.0, 0.0)

    init
    {
        // Enable continuous input on the heading PID controller to handle wraparound.
        headingController.enableContinuousInput(-PI, PI)
    }

    /** The heading of the drivebase. Used for localization. */
    val gyroHeading: Rotation2d
        get() = gyro.rotation2d

    /** The positions of all swerve modules. Used for localization. */
    val modulePositions: Array<SwerveModulePosition>
        get() = arrayOf(
            frontLeft.position,
            frontRight.position,
            rearLeft.position,
            rearRight.position)

    /** The velocities of all swerve modules. Used for telemetry. */
    val moduleVelocities: Array<SwerveModuleVelocity>
        get() = arrayOf(
            frontLeft.velocity,
            frontRight.velocity,
            rearLeft.velocity,
            rearRight.velocity)

    override fun idle(): Command
    {
        return runRepeatedly {
            frontLeft.stop()
            frontRight.stop()
            rearLeft.stop()
            rearRight.stop()
        }
            .named("Drive.Idle")
    }

    /**
     * A command that gives the driver full control of the drive.
     *
     * @param controller The driver controller.
     * @return a command that gives the driver full control of the drive
     */
    fun driverControl(controller: CommandGamepad): Command
    {
        return driveFieldRelative {
            val x = -controller.leftY
            val y = -controller.leftX
            val omega = -controller.rightX

            ChassisVelocities(
                DriveConstants.MAX_VELOCITY.times(x),
                DriveConstants.MAX_VELOCITY.times(y),
                DriveConstants.MAX_TURN_RATE.times(omega))
        }
    }

    /**
     * A command that aims the drivebase at a target. The command will exit when the necessary heading
     * is reached.
     *
     * @param robotPose A supplier for the current pose of the robot.
     * @param targetPose A supplier for the target pose to aim at.
     * @return The aiming command
     */
    fun aimAt(robotPose: () -> Pose2d, targetPose: Pose2d): Command
    {
        return driveFieldRelative {
            val robot = robotPose()
            val targetHeading = angleBetweenPoses(robot, targetPose)
            val omega: AngularVelocity = RadiansPerSecond.of(
                headingController.calculate(
                    robot.rotation.radians, targetHeading.`in`(Radians)))

            ChassisVelocities(MetersPerSecond.of(0.0), MetersPerSecond.of(0.0), omega)
        }
            .until(headingController::atSetpoint)
            .named("Drive.AimAt")
    }

    /**
     * A command that assists the driver in aiming the robot at a target pose. The driver still has
     * full control over the X and Y speeds, but heading is controlled automatically based on the
     * relative position of the robot and the target.
     *
     * @param controller The driver controller.
     * @param robotPose A supplier for the current robot pose.
     * @param targetPose A supplier for the target pose.
     * @return The aim-assist command.
     */
    fun aimAssist(
        controller: CommandGamepad, robotPose: () -> Pose2d, targetPose: () -> Pose2d): Command
    {
        return driveFieldRelative {
            // We use the driver's input to control X and Y speed as normal...
            val x = -controller.leftY
            val y = -controller.leftX

            // ... but heading is controlled automatically based on the relative position of the robot
            // and the target.
            val robot = robotPose()
            val target = targetPose()
            val targetHeading = angleBetweenPoses(robot, target)
            val omega: AngularVelocity = RadiansPerSecond.of(
                headingController.calculate(
                    robot.rotation.radians, targetHeading.`in`(Radians)))

            ChassisVelocities(
                DriveConstants.MAX_VELOCITY.times(x), DriveConstants.MAX_VELOCITY.times(y), omega)
        }
    }

    /**
     * Computes the angle from one pose to another. Useful for aiming the robot (positioned at the
     * source pose) at some target point on the field.
     *
     * @param source The source pose
     * @param target The target pose
     * @return The angle between the two poses
     */
    private fun angleBetweenPoses(source: Pose2d, target: Pose2d): Angle
    {
        // atan2 conveniently returns a value in radians between -pi and pi, so we don't need to do
        // any additional calculations to normalize the angle
        return Radians.of(atan2(target.y - source.y, target.x - source.x))
    }

    /**
     * Drives with a dynamic velocity. This command will never exit.
     *
     * @param velocities A supplier of chassis velocities. These velocities are expected to be in the
     *     field coordinate system.
     * @return a command that drives with the given velocities
     */
    fun driveFieldRelative(velocities: () -> ChassisVelocities): Command
    {
        return runRepeatedly {
            val velocity = velocities().toRobotRelative(gyroHeading)
            val swerveModuleVelocities = kinematics.toSwerveModuleVelocities(velocity)

            frontLeft.setTargetVelocity(swerveModuleVelocities[0])
            frontRight.setTargetVelocity(swerveModuleVelocities[1])
            rearLeft.setTargetVelocity(swerveModuleVelocities[2])
            rearRight.setTargetVelocity(swerveModuleVelocities[3])
        }
            .named("Drive.DriveSpeeds")
    }

    /**
     * Follows a path loaded from a file. The command will exit when the robot reaches the end of the
     * path.
     *
     * @param pathName the path to follow
     * @return a command that follows the path
     */
    fun followPath(pathName: String): Command
    {
        return run { coroutine ->
            // Load the path
            val follower = PathFollower.load(pathName)

            // Run path follower in the background
            coroutine.fork(driveFieldRelative(follower::next))

            // Wait until we reach the end of the path, then exit
            coroutine.waitUntil { follower.isDone }
        }
            .named("Drive.FollowPath[$pathName]")
    }
}
