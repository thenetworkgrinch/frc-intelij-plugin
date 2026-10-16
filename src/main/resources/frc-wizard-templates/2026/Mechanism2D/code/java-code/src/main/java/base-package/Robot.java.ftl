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

import edu.wpi.first.wpilibj.AnalogPotentiometer;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.Joystick;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;
import edu.wpi.first.wpilibj.smartdashboard.Mechanism2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismLigament2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismRoot2d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;
import edu.wpi.first.wpilibj.util.Color;
import edu.wpi.first.wpilibj.util.Color8Bit;



/**
 * This sample program shows how to use Mechanism2d - a visual representation of arms, elevators,
 * and other mechanisms on dashboards; driven by a node-based API.
 *
 * <p>Ligaments are based on other ligaments or roots, and roots are contained in the base
 * Mechanism2d object.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private static final double METERS_PER_PULSE = 0.01;
    private static final double ELEVATOR_MINIMUM_LENGTH = 0.5;
    
    private final PWMSparkMax elevatorMotor = new PWMSparkMax(0);
    private final PWMSparkMax wristMotor = new PWMSparkMax(1);
    private final AnalogPotentiometer wristPot = new AnalogPotentiometer(1, 90);
    private final Encoder elevatorEncoder = new Encoder(0, 1);
    private final Joystick joystick = new Joystick(0);
    
    private final MechanismLigament2d elevator;
    private final MechanismLigament2d wrist;
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        elevatorEncoder.setDistancePerPulse(METERS_PER_PULSE);
        
        // the main mechanism object
        Mechanism2d mech = new Mechanism2d(3, 3);
        // the mechanism root node
        MechanismRoot2d root = mech.getRoot("climber", 2, 0);
        
        // MechanismLigament2d objects represent each "section"/"stage" of the mechanism, and are based
        // off the root node or another ligament object
        elevator = root.append(new MechanismLigament2d("elevator", ELEVATOR_MINIMUM_LENGTH, 90));
        wrist =
                elevator.append(
                        new MechanismLigament2d("wrist", 0.5, 90, 6, new Color8Bit(Color.kPurple)));
        
        // post the mechanism to the dashboard
        SmartDashboard.putData("Mech2d", mech);
    }
    
    
    @Override
    public void robotPeriodic()
    {
        // update the dashboard mechanism's state
        elevator.setLength(ELEVATOR_MINIMUM_LENGTH + elevatorEncoder.getDistance());
        wrist.setAngle(wristPot.get());
    }
    
    
    @Override
    public void teleopPeriodic()
    {
        elevatorMotor.set(joystick.getRawAxis(0));
        wristMotor.set(joystick.getRawAxis(1));
    }
}
