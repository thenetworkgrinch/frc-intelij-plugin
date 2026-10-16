<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage}.subsystems;

import java.util.function.DoubleSupplier;

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.controller.SimpleMotorFeedforward;
import edu.wpi.first.units.measure.MutAngle;
import edu.wpi.first.units.measure.MutAngularVelocity;
import edu.wpi.first.units.measure.MutVoltage;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.RobotController;
import ${data.basePackage}.Constants.ShooterConstants;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.sysid.SysIdRoutine;

import static edu.wpi.first.units.Units.*;



public class Shooter extends SubsystemBase
{
    // The motor on the shooter wheel .
    private final PWMSparkMax shooterMotor = new PWMSparkMax(ShooterConstants.SHOOTER_MOTOR_PORT);
    
    // The motor on the feeder wheels.
    private final PWMSparkMax feederMotor = new PWMSparkMax(ShooterConstants.FEEDER_MOTOR_PORT);
    
    // The shooter wheel encoder
    private final Encoder shooterEncoder =
            new Encoder(
                    ShooterConstants.ENCODER_PORTS[0],
                    ShooterConstants.ENCODER_PORTS[1],
                    ShooterConstants.ENCODER_REVERSED);
    
    // Mutable holder for unit-safe voltage values, persisted to avoid reallocation.
    private final MutVoltage appliedVoltage = Volts.mutable(0);
    // Mutable holder for unit-safe linear distance values, persisted to avoid reallocation.
    private final MutAngle angle = Radians.mutable(0);
    // Mutable holder for unit-safe linear velocity values, persisted to avoid reallocation.
    private final MutAngularVelocity velocity = RadiansPerSecond.mutable(0);
    
    // Create a new SysId routine for characterizing the shooter.
    private final SysIdRoutine sysIdRoutine =
            new SysIdRoutine(
                    // Empty config defaults to 1 volt/second ramp rate and 7 volt step voltage.
                    new SysIdRoutine.Config(),
                    new SysIdRoutine.Mechanism(
                            // Tell SysId how to plumb the driving voltage to the motor(s).
                            shooterMotor::setVoltage,
                            // Tell SysId how to record a frame of data for each motor on the mechanism being
                            // characterized.
                            log -> {
                                // Record a frame for the shooter motor.
                                log.motor("shooter-wheel")
                                   .voltage(
                                           appliedVoltage.mut_replace(
                                                   shooterMotor.get() * RobotController.getBatteryVoltage(), Volts))
                                   .angularPosition(angle.mut_replace(shooterEncoder.getDistance(), Rotations))
                                   .angularVelocity(
                                           velocity.mut_replace(shooterEncoder.getRate(), RotationsPerSecond));
                            },
                            // Tell SysId to make generated commands require this subsystem, suffix test state in
                            // WPILog with this subsystem's name ("shooter")
                            this));
    // PID controller to run the shooter wheel in closed-loop, set the constants equal to those
    // calculated by SysId
    private final PIDController shooterFeedback = new PIDController(ShooterConstants.P, 0, 0);
    // Feedforward controller to run the shooter wheel in closed-loop, set the constants equal to
    // those calculated by SysId
    private final SimpleMotorFeedforward shooterFeedforward =
            new SimpleMotorFeedforward(
                    ShooterConstants.S_VOLTS,
                    ShooterConstants.V_VOLT_SECONDS_PER_ROTATION,
                    ShooterConstants.A_VOLT_SECONDS_SQUARED_PER_ROTATION);
    
    
    /** Creates a new Shooter subsystem. */
    public Shooter()
    {
        // Sets the distance per pulse for the encoders
        shooterEncoder.setDistancePerPulse(ShooterConstants.ENCODER_DISTANCE_PER_PULSE);
    }
    
    
    /**
     * Returns a command that runs the shooter at a specifc velocity.
     *
     * @param shooterSpeed The commanded shooter wheel speed in rotations per second
     */
    public Command runShooter(DoubleSupplier shooterSpeed)
    {
        // Run shooter wheel at the desired speed using a PID controller and feedforward.
        return run(() -> {
            shooterMotor.setVoltage(
                    shooterFeedback.calculate(shooterEncoder.getRate(), shooterSpeed.getAsDouble())
                    + shooterFeedforward.calculate(shooterSpeed.getAsDouble()));
            feederMotor.set(ShooterConstants.FEEDER_SPEED);
        })
                .finallyDo(
                        () -> {
                            shooterMotor.stopMotor();
                            feederMotor.stopMotor();
                        })
                .withName("runShooter");
    }
    
    
    /**
     * Returns a command that will execute a quasistatic test in the given direction.
     *
     * @param direction The direction (forward or reverse) to run the test in
     */
    public Command sysIdQuasistatic(SysIdRoutine.Direction direction)
    {
        return sysIdRoutine.quasistatic(direction);
    }
    
    
    /**
     * Returns a command that will execute a dynamic test in the given direction.
     *
     * @param direction The direction (forward or reverse) to run the test in
     */
    public Command sysIdDynamic(SysIdRoutine.Direction direction)
    {
        return sysIdRoutine.dynamic(direction);
    }
}
