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

package ${data.basePackage};

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.controller.SimpleMotorFeedforward;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.Joystick;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.Ultrasonic;
import edu.wpi.first.wpilibj.event.BooleanEvent;
import edu.wpi.first.wpilibj.event.EventLoop;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



public class ${data.robotClassSimpleName} extends TimedRobot
{
    public static final int SHOT_VELOCITY = 200; // rpm
    public static final int TOLERANCE = 8; // rpm
    public static final int KICKER_THRESHOLD = 15; // mm
    
    private final PWMSparkMax shooter = new PWMSparkMax(0);
    private final Encoder shooterEncoder = new Encoder(0, 1);
    private final PIDController controller = new PIDController(0.3, 0, 0);
    private final SimpleMotorFeedforward ff = new SimpleMotorFeedforward(0.1, 0.065);
    
    private final PWMSparkMax kicker = new PWMSparkMax(1);
    private final Ultrasonic kickerSensor = new Ultrasonic(2, 3);
    
    private final PWMSparkMax intake = new PWMSparkMax(2);
    
    private final EventLoop loop = new EventLoop();
    private final Joystick joystick = new Joystick(0);
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        controller.setTolerance(TOLERANCE);
        
        BooleanEvent isBallAtKicker =
                new BooleanEvent(loop, () -> kickerSensor.getRangeMM() < KICKER_THRESHOLD);
        BooleanEvent intakeButton = new BooleanEvent(loop, () -> joystick.getRawButton(2));
        
        // if the thumb button is held
        intakeButton
                // and there is not a ball at the kicker
                .and(isBallAtKicker.negate())
                // activate the intake
                .ifHigh(() -> intake.set(0.5));
        
        // if the thumb button is not held
        intakeButton
                .negate()
                // or there is a ball in the kicker
                .or(isBallAtKicker)
                // stop the intake
                .ifHigh(intake::stopMotor);
        
        BooleanEvent shootTrigger = new BooleanEvent(loop, joystick::getTrigger);
        
        // if the trigger is held
        shootTrigger
                // accelerate the shooter wheel
                .ifHigh(
                        () -> {
                            shooter.setVoltage(
                                    controller.calculate(shooterEncoder.getRate(), SHOT_VELOCITY)
                                    + ff.calculate(SHOT_VELOCITY));
                        });
        
        // if not, stop
        shootTrigger.negate().ifHigh(shooter::stopMotor);
        
        BooleanEvent atTargetVelocity =
                new BooleanEvent(loop, controller::atSetpoint)
                        // debounce for more stability
                        .debounce(0.2);
        
        // if we're at the target velocity, kick the ball into the shooter wheel
        atTargetVelocity.ifHigh(() -> kicker.set(0.7));
        
        // when we stop being at the target velocity, it means the ball was shot
        atTargetVelocity
                .falling()
                // so stop the kicker
                .ifHigh(kicker::stopMotor);
    }
    
    
    @Override
    public void robotPeriodic()
    {
        // poll all the bindings
        loop.poll();
    }
}
