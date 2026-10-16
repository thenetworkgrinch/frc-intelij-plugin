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

import edu.wpi.first.epilogue.Logged;
import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.controller.SimpleMotorFeedforward;
import edu.wpi.first.wpilibj.Encoder;
import ${data.basePackage}.Constants.ShooterConstants;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;

import static edu.wpi.first.wpilibj2.command.Commands.parallel;
import static edu.wpi.first.wpilibj2.command.Commands.waitUntil;



@Logged
public class Shooter extends SubsystemBase
{
    private final PWMSparkMax shooterMotor = new PWMSparkMax(ShooterConstants.SHOOTER_MOTOR_PORT);
    private final PWMSparkMax feederMotor = new PWMSparkMax(ShooterConstants.FEEDER_MOTOR_PORT);
    private final Encoder shooterEncoder =
            new Encoder(
                    ShooterConstants.ENCODER_PORTS[0],
                    ShooterConstants.ENCODER_PORTS[1],
                    ShooterConstants.ENCODER_REVERSED);
    private final SimpleMotorFeedforward shooterFeedforward =
            new SimpleMotorFeedforward(
                    ShooterConstants.S_VOLTS, ShooterConstants.V_VOLT_SECONDS_PER_ROTATION);
    private final PIDController shooterFeedback = new PIDController(ShooterConstants.P, 0.0, 0.0);
    
    
    /** The shooter subsystem for the robot. */
    public Shooter()
    {
        shooterFeedback.setTolerance(ShooterConstants.SHOOTER_TOLERANCE_RPS);
        shooterEncoder.setDistancePerPulse(ShooterConstants.ENCODER_DISTANCE_PER_PULSE);
        
        // Set default command to turn off both the shooter and feeder motors, and then idle
        setDefaultCommand(
                runOnce(
                        () -> {
                            shooterMotor.disable();
                            feederMotor.disable();
                        })
                        .andThen(run(() -> {}))
                        .withName("Idle"));
    }
    
    
    /**
     * Returns a command to shoot the balls currently stored in the robot. Spins the shooter flywheel
     * up to the specified setpoint, and then runs the feeder motor.
     *
     * @param setpointRotationsPerSecond The desired shooter velocity
     */
    public Command shootCommand(double setpointRotationsPerSecond)
    {
        return parallel(
                // Run the shooter flywheel at the desired setpoint using feedforward and feedback
                run(
                        () -> {
                            shooterMotor.set(
                                    shooterFeedforward.calculate(setpointRotationsPerSecond)
                                    + shooterFeedback.calculate(
                                            shooterEncoder.getRate(), setpointRotationsPerSecond));
                        }),
                
                // Wait until the shooter has reached the setpoint, and then run the feeder
                waitUntil(shooterFeedback::atSetpoint).andThen(() -> feederMotor.set(1)))
                .withName("Shoot");
    }
}
