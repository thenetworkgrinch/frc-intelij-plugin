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
import org.wpilib.drivers.motor.PWMSparkMax
import [=data.basePackage].Constants.ShooterConstants
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.math.controller.PIDController
import org.wpilib.math.controller.SimpleMotorFeedforward
import org.wpilib.system.RobotController
import org.wpilib.units.Units.Rotations
import org.wpilib.units.Units.RotationsPerSecond
import org.wpilib.units.Units.Volts

class Shooter : SubsystemBase()
{
    // The motor on the shooter wheel .
    private val shooterMotor = PWMSparkMax(ShooterConstants.SHOOTER_MOTOR_PORT)

    // The motor on the feeder wheels.
    private val feederMotor = PWMSparkMax(ShooterConstants.FEEDER_MOTOR_PORT)

    // The shooter wheel encoder
    private val shooterEncoder = Encoder(
        ShooterConstants.ENCODER_PORTS[0],
        ShooterConstants.ENCODER_PORTS[1],
        ShooterConstants.ENCODER_REVERSED)

    // Create a new SysId routine for characterizing the shooter.
    private val sysIdRoutine = SysIdRoutine(
        // Empty config defaults to 1 volt/second ramp rate and 7 volt step voltage.
        SysIdRoutine.Config(),
        SysIdRoutine.Mechanism(
            // Tell SysId how to plumb the driving voltage to the motor(s).
            shooterMotor::setVoltage,
            // Tell SysId how to record a frame of data for each motor on the mechanism being
            // characterized.
            { log ->
                // Record a frame for the shooter motor.
                log.motor("shooter-wheel")
                    .voltage(Volts.of(shooterMotor.throttle * RobotController.getBatteryVoltage()))
                    .angularPosition(Rotations.of(shooterEncoder.distance))
                    .angularVelocity(RotationsPerSecond.of(shooterEncoder.rate))
            },
            // Tell SysId to make generated commands require this subsystem, suffix test state in
            // WPILog with this subsystem's name ("shooter")
            this))
    // PID controller to run the shooter wheel in closed-loop, set the constants equal to those
    // calculated by SysId
    private val shooterFeedback = PIDController(ShooterConstants.kP, 0.0, 0.0)
    // Feedforward controller to run the shooter wheel in closed-loop, set the constants equal to
    // those calculated by SysId
    private val shooterFeedforward =
        SimpleMotorFeedforward(ShooterConstants.kS, ShooterConstants.kV, ShooterConstants.kA)

    /** Creates a new Shooter subsystem. */
    init
    {
        // Sets the distance per pulse for the encoders
        shooterEncoder.distancePerPulse = ShooterConstants.ENCODER_DISTANCE_PER_PULSE
    }

    /**
     * Returns a command that runs the shooter at a specifc velocity.
     *
     * @param shooterVelocity The commanded shooter wheel velocity in rotations per second
     */
    fun runShooter(shooterVelocity: DoubleSupplier): Command
    {
        // Run shooter wheel at the desired velocity using a PID controller and feedforward.
        return run {
                shooterMotor.setVoltage(
                    shooterFeedback.calculate(shooterEncoder.rate, shooterVelocity.asDouble)
                        + shooterFeedforward.calculate(shooterVelocity.asDouble))
                feederMotor.throttle = ShooterConstants.FEEDER_VELOCITY
            }
            .finallyDo { ->
                shooterMotor.setVoltage(0.0)
                feederMotor.setVoltage(0.0)
            }
            .withName("runShooter")
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
