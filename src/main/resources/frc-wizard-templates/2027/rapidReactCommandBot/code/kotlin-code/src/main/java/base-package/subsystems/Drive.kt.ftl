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

import org.wpilib.epilogue.Logged
import org.wpilib.epilogue.NotLogged
import java.util.function.DoubleSupplier
import org.wpilib.command2.Command
import org.wpilib.command2.SubsystemBase
import org.wpilib.drive.DifferentialDrive
import org.wpilib.drivers.motor.PWMSparkMax
import [=data.basePackage].Constants.DriveConstants
import org.wpilib.hardware.imu.OnboardIMU
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.math.controller.ProfiledPIDController
import org.wpilib.math.controller.SimpleMotorFeedforward
import org.wpilib.math.trajectory.TrapezoidProfile
import org.wpilib.system.RobotController
import kotlin.math.max

@Logged
class Drive : SubsystemBase()
{
    // The motors on the left side of the drive.
    private val leftLeader = PWMSparkMax(DriveConstants.LEFT_MOTOR1_PORT)
    private val leftFollower = PWMSparkMax(DriveConstants.LEFT_MOTOR2_PORT)

    // The motors on the right side of the drive.
    private val rightLeader = PWMSparkMax(DriveConstants.RIGHT_MOTOR1_PORT)
    private val rightFollower = PWMSparkMax(DriveConstants.RIGHT_MOTOR2_PORT)

    // The robot's drive
    @NotLogged // Would duplicate motor data, there's no point sending it twice
    private val drive = DifferentialDrive(leftLeader::setThrottle, rightLeader::setThrottle)

    // The left-side drive encoder
    private val leftEncoder = Encoder(
        DriveConstants.LEFT_ENCODER_PORTS[0],
        DriveConstants.LEFT_ENCODER_PORTS[1],
        DriveConstants.LEFT_ENCODER_REVERSED)

    // The right-side drive encoder
    private val rightEncoder = Encoder(
        DriveConstants.RIGHT_ENCODER_PORTS[0],
        DriveConstants.RIGHT_ENCODER_PORTS[1],
        DriveConstants.RIGHT_ENCODER_REVERSED)

    private val imu = OnboardIMU(OnboardIMU.MountOrientation.FLAT)
    private val controller = ProfiledPIDController(
        DriveConstants.TURN_P,
        DriveConstants.TURN_I,
        DriveConstants.TURN_D,
        TrapezoidProfile.Constraints(
            DriveConstants.MAX_TURN_RATE_DEG_PER_S,
            DriveConstants.MAX_TURN_ACCELERATION_DEG_PER_S_SQUARED))
    private val feedforward = SimpleMotorFeedforward(DriveConstants.ks, DriveConstants.kv, DriveConstants.ka)

    /** Creates a new Drive subsystem. */
    init
    {
        leftLeader.addFollower(leftFollower)
        rightLeader.addFollower(rightFollower)

        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightLeader.inverted = true

        // Sets the distance per pulse for the encoders
        leftEncoder.distancePerPulse = DriveConstants.ENCODER_DISTANCE_PER_PULSE
        rightEncoder.distancePerPulse = DriveConstants.ENCODER_DISTANCE_PER_PULSE

        // Set the controller to be continuous (because it is an angle controller)
        controller.enableContinuousInput(-180.0, 180.0)
        // Set the controller tolerance - the delta tolerance ensures the robot is stationary at the
        // setpoint before it is considered as having reached the reference
        controller.setTolerance(DriveConstants.TURN_TOLERANCE_DEG, DriveConstants.TURN_RATE_TOLERANCE_DEG_PER_S)
    }

    /**
     * Returns a command that drives the robot with arcade controls.
     *
     * @param fwd the commanded forward movement
     * @param rot the commanded rotation
     */
    fun arcadeDriveCommand(fwd: DoubleSupplier, rot: DoubleSupplier): Command
    {
        // A split-stick arcade command, with forward/backward controlled by the left
        // hand, and turning controlled by the right.
        return run { drive.arcadeDrive(fwd.asDouble, rot.asDouble) }
            .withName("arcadeDrive")
    }

    /**
     * Returns a command that drives the robot forward a specified distance at a specified velocity.
     *
     * @param distance The distance to drive forward in meters
     * @param velocity The fraction of max velocity at which to drive
     */
    fun driveDistanceCommand(distance: Double, velocity: Double): Command
    {
        return runOnce {
                // Reset encoders at the start of the command
                leftEncoder.reset()
                rightEncoder.reset()
            }
            // Drive forward at specified velocity
            .andThen(run { drive.arcadeDrive(velocity, 0.0) })
            // End command when we've traveled the specified distance
            .until { max(leftEncoder.distance, rightEncoder.distance) >= distance }
            // Stop the drive when the command ends
            .finallyDo { _ -> drive.arcadeDrive(0.0, 0.0) }
    }

    /**
     * Returns a command that turns to robot to the specified angle using a motion profile and PID
     * controller.
     *
     * @param angleDeg The angle to turn to
     */
    fun turnToAngleCommand(angleDeg: Double): Command
    {
        return startRun(
                { controller.reset(imu.rotation2d.degrees) },
                {
                    drive.arcadeDrive(
                        0.0,
                        controller.calculate(imu.rotation2d.degrees, angleDeg)
                            // Divide feedforward voltage by battery voltage to normalize it to [-1, 1]
                            + feedforward.calculate(controller.setpoint.velocity)
                                / RobotController.getBatteryVoltage())
                })
            .until(controller::atGoal)
            .finallyDo { -> drive.arcadeDrive(0.0, 0.0) }
    }
}
