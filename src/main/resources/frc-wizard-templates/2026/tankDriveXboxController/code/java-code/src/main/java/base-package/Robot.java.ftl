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

import edu.wpi.first.util.sendable.SendableRegistry;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.XboxController;
import edu.wpi.first.wpilibj.drive.DifferentialDrive;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



/**
 * This is a demo program showing the use of the DifferentialDrive class. Runs the motors with tank
 * steering and an Xbox controller.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final PWMSparkMax leftMotor = new PWMSparkMax(0);
    private final PWMSparkMax rightMotor = new PWMSparkMax(1);
    private final DifferentialDrive robotDrive =
            new DifferentialDrive(leftMotor::set, rightMotor::set);
    private final XboxController driverController = new XboxController(0);
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        SendableRegistry.addChild(robotDrive, leftMotor);
        SendableRegistry.addChild(robotDrive, rightMotor);
        
        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightMotor.setInverted(true);
    }
    
    
    @Override
    public void teleopPeriodic()
    {
        // Drive with tank drive.
        // That means that the Y axis of the left stick moves the left side
        // of the robot forward and backward, and the Y axis of the right stick
        // moves the right side of the robot forward and backward.
        robotDrive.tankDrive(-driverController.getLeftY(), -driverController.getRightY());
    }
}
