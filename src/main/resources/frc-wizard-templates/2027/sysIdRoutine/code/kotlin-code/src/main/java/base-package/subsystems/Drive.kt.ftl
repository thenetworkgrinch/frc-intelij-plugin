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

import java.util.function.DoubleSupplier
import org.wpilib.command2.Command
import org.wpilib.command2.SubsystemBase
import org.wpilib.command2.sysid.SysIdRoutine
import org.wpilib.drive.DifferentialDrive
import org.wpilib.drivers.motor.PWMSparkMax
import [=data.basePackage].Constants.DriveConstants
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.system.RobotController
import org.wpilib.units.Units.Meters
import org.wpilib.units.Units.MetersPerSecond
import org.wpilib.units.Units.Volts

class Drive : SubsystemBase()
{
    // The motors on the left side of the drive.
    private val leftMotor = PWMSparkMax(DriveConstants.LEFT_MOTOR1_PORT)

    // The motors on the right side of the drive.
    private val rightMotor = PWMSparkMax(DriveConstants.RIGHT_MOTOR1_PORT)

    // The robot's drive
    private val drive = DifferentialDrive(leftMotor::setThrottle, rightMotor::setThrottle)

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

    // Create a new SysId routine for characterizing the drive.
    private val sysIdRoutine = SysIdRoutine(
        // Empty config defaults to 1 volt/second ramp rate and 7 volt step voltage.
        SysIdRoutine.Config(),
        SysIdRoutine.Mechanism(
            // Tell SysId how to plumb the driving voltage to the motors.
            { voltage ->
                leftMotor.setVoltage(voltage)
                rightMotor.setVoltage(voltage)
            },
            // Tell SysId how to record a frame of data for each motor on the mechanism being
            // characterized.
            { log ->
                // Record a frame for the left motors.  Since these share an encoder, we consider
                // the entire group to be one motor.
                log.motor("drive-left")
                    .voltage(Volts.of(leftMotor.throttle * RobotController.getBatteryVoltage()))
                    .linearPosition(Meters.of(leftEncoder.distance))
                    .linearVelocity(MetersPerSecond.of(leftEncoder.rate))
                // Record a frame for the right motors.  Since these share an encoder, we consider
                // the entire group to be one motor.
                log.motor("drive-right")
                    .voltage(Volts.of(rightMotor.throttle * RobotController.getBatteryVoltage()))
                    .linearPosition(Meters.of(rightEncoder.distance))
                    .linearVelocity(MetersPerSecond.of(rightEncoder.rate))
            },
            // Tell SysId to make generated commands require this subsystem, suffix test state in
            // WPILog with this subsystem's name ("drive")
            this))

    /** Creates a new Drive subsystem. */
    init
    {
        // Add the second motors on each side of the drivetrain
        leftMotor.addFollower(PWMSparkMax(DriveConstants.LEFT_MOTOR2_PORT))
        rightMotor.addFollower(PWMSparkMax(DriveConstants.RIGHT_MOTOR2_PORT))

        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightMotor.inverted = true

        // Sets the distance per pulse for the encoders
        leftEncoder.distancePerPulse = DriveConstants.ENCODER_DISTANCE_PER_PULSE
        rightEncoder.distancePerPulse = DriveConstants.ENCODER_DISTANCE_PER_PULSE
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
     * Returns a command that will execute a quasistatic test in the given direction.
     *
     * @param direction The direction (forward or reverse) to run the test in
     */
    fun sysIdQuasistatic(direction: SysIdRoutine.Direction): Command = sysIdRoutine.quasistatic(direction)

    /**
     * Returns a command that will execute a dynamic test in the given direction.
     *
     * @param direction The direction (forward or reverse) to run the test in
     */
    fun sysIdDynamic(direction: SysIdRoutine.Direction): Command = sysIdRoutine.dynamic(direction)
}
