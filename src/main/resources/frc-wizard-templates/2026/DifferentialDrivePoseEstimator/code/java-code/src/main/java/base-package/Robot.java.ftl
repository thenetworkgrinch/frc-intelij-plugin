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

import edu.wpi.first.math.filter.SlewRateLimiter;
import edu.wpi.first.networktables.DoubleArrayTopic;
import edu.wpi.first.networktables.NetworkTableInstance;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.XboxController;



public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final NetworkTableInstance inst = NetworkTableInstance.getDefault();
    private final DoubleArrayTopic doubleArrayTopic =
            inst.getDoubleArrayTopic("doubleArrayTopic");
    
    private final XboxController controller = new XboxController(0);
    private final Drivetrain drive = new Drivetrain(doubleArrayTopic);
    
    // Slew rate limiters to make joystick inputs more gentle; 1/3 sec from 0 to 1.
    private final SlewRateLimiter speedLimiter = new SlewRateLimiter(3);
    private final SlewRateLimiter rotateLimiter = new SlewRateLimiter(3);
    
    
    @Override
    public void autonomousPeriodic()
    {
        teleopPeriodic();
        drive.updateOdometry();
    }
    
    
    @Override
    public void simulationPeriodic()
    {
        drive.simulationPeriodic();
    }
    
    
    @Override
    public void robotPeriodic()
    {
        drive.periodic();
    }
    
    
    @Override
    public void teleopPeriodic()
    {
        // Get the x speed. We are inverting this because Xbox controllers return
        // negative values when we push forward.
        final var xSpeed = -speedLimiter.calculate(controller.getLeftY()) * Drivetrain.MAX_SPEED;
        
        // Get the rate of angular rotation. We are inverting this because we want a
        // positive value when we pull to the left (remember, CCW is positive in
        // mathematics). Xbox controllers return positive values when you pull to
        // the right by default.
        final var rot = -rotateLimiter.calculate(controller.getRightX()) * Drivetrain.MAX_ANGULAR_SPEED;
        
        drive.drive(xSpeed, rot);
    }
}
