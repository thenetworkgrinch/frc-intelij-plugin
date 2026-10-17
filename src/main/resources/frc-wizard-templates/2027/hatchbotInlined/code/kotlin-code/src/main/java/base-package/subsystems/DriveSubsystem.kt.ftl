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

import org.wpilib.command2.SubsystemBase
import org.wpilib.drive.DifferentialDrive
import org.wpilib.drivers.motor.PWMSparkMax
import [=data.basePackage].Constants.DriveConstants
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.telemetry.TelemetryTable

/** Creates a new DriveSubsystem. */
class DriveSubsystem : SubsystemBase()
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
        DriveConstants.LEFT_ENCODER_REVERSED,
                                     )

    // The right-side drive encoder
    private val rightEncoder = Encoder(
        DriveConstants.RIGHT_ENCODER_PORTS[0],
        DriveConstants.RIGHT_ENCODER_PORTS[1],
        DriveConstants.RIGHT_ENCODER_REVERSED,
                                      )

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

    /** Resets the drive encoders to currently read a position of 0. */
    fun resetEncoders()
    {
        leftEncoder.reset()
        rightEncoder.reset()
    }

    /**
     * Gets the average distance of the TWO encoders.
     *
     * @return the average of the TWO encoder readings
     */
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
        super.logTo(table)
        // Publish encoder distances to telemetry.
        table.log("leftDistance", leftEncoder.distance)
        table.log("rightDistance", rightEncoder.distance)
    }
}
