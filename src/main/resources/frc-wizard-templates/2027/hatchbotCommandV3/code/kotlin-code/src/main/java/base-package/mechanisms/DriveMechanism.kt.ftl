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

import org.wpilib.command3.Command
import org.wpilib.command3.Mechanism
import org.wpilib.drive.DifferentialDrive
import org.wpilib.drivers.motor.PWMSparkMax
import [=data.basePackage].Constants.DriveConstants
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.telemetry.TelemetryLoggable
import org.wpilib.telemetry.TelemetryTable

class DriveMechanism : Mechanism, TelemetryLoggable
{
    // The motors on the left side of the drive.
    private val leftLeader = PWMSparkMax(DriveConstants.LEFT_MOTOR1_PORT)
    private val leftFollower = PWMSparkMax(DriveConstants.LEFT_MOTOR2_PORT)

    // The motors on the right side of the drive.
    private val rightLeader = PWMSparkMax(DriveConstants.RIGHT_MOTOR1_PORT)
    private val rightFollower = PWMSparkMax(DriveConstants.RIGHT_MOTOR2_PORT)

    // The robot's drive
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

    /** Creates a new DriveMechanism. */
    init
    {
        leftLeader.addFollower(leftFollower)
        rightLeader.addFollower(rightFollower)

        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightLeader.setInverted(true)

        // Sets the distance per pulse for the encoders
        leftEncoder.setDistancePerPulse(DriveConstants.ENCODER_DISTANCE_PER_PULSE)
        rightEncoder.setDistancePerPulse(DriveConstants.ENCODER_DISTANCE_PER_PULSE)
    }

    /**
     * Drives the robot using arcade controls.
     *
     * @param speed The speed to drive at, from -1 (full reverse) to +1 (full forward)
     * @param turn The turn rate, from -1 (full counterclockwise) to +1 (full clockwise)
     * @return A command that drives the robot using arcade controls
     */
    fun arcadeDrive(speed: () -> Double, turn: () -> Double): Command
    {
        return runRepeatedly { drive.arcadeDrive(speed(), turn()) }
            .named("Arcade Drive")
    }

    /**
     * Drives a set distance, in inches, at a set speed ratio from 0-1. The command will exit when the
     * distance has been reached.
     *
     * @param distance How many inches to travel. This may be negative to drive backwards.
     * @param speed Speed ratio from 0 (off) to 1 (full speed). Negative values will make the robot
     *     drive the wrong way.
     * @return A command that drives a specified distance.
     */
    fun driveDistance(distance: Double, speed: Double): Command
    {
        return run { coroutine ->
            resetEncoders()

            if (distance >= 0)
            {
                // drive forward
                while (averageEncoderDistance < distance)
                {
                    drive.tankDrive(speed, 0.0)
                    coroutine.yield()
                }
            }
            else
            {
                // drive backward
                while (averageEncoderDistance > distance)
                {
                    drive.tankDrive(-speed, 0.0)
                    coroutine.yield()
                }
            }

            // Finally, stop
            drive.tankDrive(0.0, 0.0)
        }
            .named("Drive Distance[$distance@$speed]")
    }

    /** Resets the drive encoders to currently read a position of 0. */
    private fun resetEncoders()
    {
        leftEncoder.reset()
        rightEncoder.reset()
    }

    /** The average distance of the TWO encoders. */
    val averageEncoderDistance: Double
        get() = (leftEncoder.distance + rightEncoder.distance) / 2.0

    /**
     * Sets the max output of the drive. Useful for scaling the drive to drive more slowly.
     *
     * @param maxOutput the maximum output to which the drive will be constrained
     */
    fun setMaxOutput(maxOutput: Double)
    {
        drive.setMaxOutput(maxOutput)
    }

    override fun logTo(table: TelemetryTable)
    {
        table.log("leftDistance", leftEncoder.distance)
        table.log("rightDistance", rightEncoder.distance)
    }
}
