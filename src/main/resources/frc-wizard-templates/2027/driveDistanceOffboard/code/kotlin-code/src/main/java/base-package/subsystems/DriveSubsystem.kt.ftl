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

import org.wpilib.command2.Command
import org.wpilib.command2.SubsystemBase
import org.wpilib.drive.DifferentialDrive
import [=data.basePackage].Constants.DriveConstants
import [=data.basePackage].ExampleSmartMotorController
import org.wpilib.math.controller.SimpleMotorFeedforward
import org.wpilib.math.trajectory.TrapezoidProfile
import org.wpilib.math.trajectory.TrapezoidProfile.State
import org.wpilib.system.RobotController
import org.wpilib.system.Timer

class DriveSubsystem : SubsystemBase()
{
    // The motors on the left side of the drive.
    private val leftLeader = ExampleSmartMotorController(DriveConstants.LEFT_MOTOR1_PORT)

    private val leftFollower = ExampleSmartMotorController(DriveConstants.LEFT_MOTOR2_PORT)

    // The motors on the right side of the drive.
    private val rightLeader = ExampleSmartMotorController(DriveConstants.RIGHT_MOTOR1_PORT)

    private val rightFollower = ExampleSmartMotorController(DriveConstants.RIGHT_MOTOR2_PORT)

    // The feedforward controller.
    private val feedforward = SimpleMotorFeedforward(DriveConstants.ks, DriveConstants.kv, DriveConstants.ka)

    // The robot's drive
    private val drive = DifferentialDrive(leftLeader::setThrottle, rightLeader::setThrottle)

    // The trapezoid profile
    private val profile =
        TrapezoidProfile(TrapezoidProfile.Constraints(DriveConstants.MAX_VELOCITY, DriveConstants.MAX_ACCELERATION))

    // The timer
    private val timer = Timer()

    private var initialLeftDistance = 0.0
    private var initialRightDistance = 0.0

    /** Creates a new DriveSubsystem. */
    init
    {
        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightLeader.setInverted(true)

        leftFollower.follow(leftLeader)
        rightFollower.follow(rightLeader)

        leftLeader.setPID(DriveConstants.kp, 0.0, 0.0)
        rightLeader.setPID(DriveConstants.kp, 0.0, 0.0)
    }

    /**
     * Drives the robot using arcade controls.
     *
     * @param fwd the commanded forward movement
     * @param rot the commanded rotation
     */
    fun arcadeDrive(fwd: Double, rot: Double)
    {
        drive.arcadeDrive(fwd, rot)
    }

    /**
     * Attempts to follow the given drive states using offboard PID.
     *
     * @param currentLeft The current left wheel state.
     * @param currentRight The current right wheel state.
     * @param nextLeft The next left wheel state.
     * @param nextRight The next right wheel state.
     */
    fun setDriveStates(
        currentLeft: TrapezoidProfile.State,
        currentRight: TrapezoidProfile.State,
        nextLeft: TrapezoidProfile.State,
        @Suppress("UNUSED_PARAMETER") nextRight: TrapezoidProfile.State)
    {
        // Feedforward is divided by battery voltage to normalize it to [-1, 1]
        leftLeader.setSetpoint(
            ExampleSmartMotorController.PIDMode.POSITION,
            currentLeft.position,
            feedforward.calculate(currentLeft.velocity, nextLeft.velocity) / RobotController.getBatteryVoltage())
        rightLeader.setSetpoint(
            ExampleSmartMotorController.PIDMode.POSITION,
            currentRight.position,
            feedforward.calculate(currentLeft.velocity, nextLeft.velocity) / RobotController.getBatteryVoltage())
    }

    /** The left encoder distance. */
    val leftEncoderDistance: Double
        get() = leftLeader.getEncoderDistance()

    /** The right encoder distance. */
    val rightEncoderDistance: Double
        get() = rightLeader.getEncoderDistance()

    /** Resets the drive encoders. */
    fun resetEncoders()
    {
        leftLeader.resetEncoder()
        rightLeader.resetEncoder()
    }

    /**
     * Sets the max output of the drive. Useful for scaling the drive to drive more slowly.
     *
     * @param maxOutput the maximum output to which the drive will be constrained
     */
    fun setMaxOutput(maxOutput: Double)
    {
        drive.setMaxOutput(maxOutput)
    }

    /**
     * Creates a command to drive forward a specified distance using a motion profile.
     *
     * @param distance The distance to drive forward.
     * @return A command.
     */
    fun profiledDriveDistance(distance: Double): Command =
        startRun(
            {
                // Restart timer so profile setpoints start at the beginning
                timer.restart()
                resetEncoders()
            },
            {
                // Current state never changes, so we need to use a timer to get the setpoints we need
                // to be at
                val currentTime = timer.get()
                val currentSetpoint = profile.calculate(currentTime, State(), State(distance, 0.0))
                val nextSetpoint = profile.calculate(currentTime + DriveConstants.DT, State(), State(distance, 0.0))
                setDriveStates(currentSetpoint, currentSetpoint, nextSetpoint, nextSetpoint)
            })
            .until { profile.isFinished(0.0) }

    /**
     * Creates a command to drive forward a specified distance using a motion profile without
     * resetting the encoders.
     *
     * @param distance The distance to drive forward.
     * @return A command.
     */
    fun dynamicProfiledDriveDistance(distance: Double): Command =
        startRun(
            {
                // Restart timer so profile setpoints start at the beginning
                timer.restart()
                // Store distance so we know the target distance for each encoder
                initialLeftDistance = leftEncoderDistance
                initialRightDistance = rightEncoderDistance
            },
            {
                // Current state never changes for the duration of the command, so we need to use a
                // timer to get the setpoints we need to be at
                val currentTime = timer.get()
                val currentLeftSetpoint = profile.calculate(
                    currentTime,
                    State(initialLeftDistance, 0.0),
                    State(initialLeftDistance + distance, 0.0))
                val currentRightSetpoint = profile.calculate(
                    currentTime,
                    State(initialRightDistance, 0.0),
                    State(initialRightDistance + distance, 0.0))
                val nextLeftSetpoint = profile.calculate(
                    currentTime + DriveConstants.DT,
                    State(initialLeftDistance, 0.0),
                    State(initialLeftDistance + distance, 0.0))
                val nextRightSetpoint = profile.calculate(
                    currentTime + DriveConstants.DT,
                    State(initialRightDistance, 0.0),
                    State(initialRightDistance + distance, 0.0))
                setDriveStates(currentLeftSetpoint, currentRightSetpoint, nextLeftSetpoint, nextRightSetpoint)
            })
            .until { profile.isFinished(0.0) }
}
