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

import edu.wpi.first.networktables.GenericEntry;
import edu.wpi.first.util.sendable.SendableRegistry;
import edu.wpi.first.wpilibj.AnalogPotentiometer;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.drive.DifferentialDrive;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;
import edu.wpi.first.wpilibj.shuffleboard.BuiltInLayouts;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardLayout;
import edu.wpi.first.wpilibj.shuffleboard.ShuffleboardTab;



public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final PWMSparkMax leftDriveMotor = new PWMSparkMax(0);
    private final PWMSparkMax rightDriveMotor = new PWMSparkMax(1);
    private final DifferentialDrive tankDrive =
            new DifferentialDrive(leftDriveMotor::set, rightDriveMotor::set);
    private final Encoder leftEncoder = new Encoder(0, 1);
    private final Encoder rightEncoder = new Encoder(2, 3);
    
    private final PWMSparkMax elevatorMotor = new PWMSparkMax(2);
    private final AnalogPotentiometer elevatorPot = new AnalogPotentiometer(0);
    private final GenericEntry maxSpeed;
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        SendableRegistry.addChild(tankDrive, leftDriveMotor);
        SendableRegistry.addChild(tankDrive, rightDriveMotor);
        
        // Add a 'max speed' widget to a tab named 'Configuration', using a number slider
        // The widget will be placed in the second column and row and will be TWO columns wide
        maxSpeed =
                Shuffleboard.getTab("Configuration")
                            .add("Max Speed", 1)
                            .withWidget("Number Slider")
                            .withPosition(1, 1)
                            .withSize(2, 1)
                            .getEntry();
        
        // Add the tank drive and encoders to a 'Drivebase' tab
        ShuffleboardTab driveBaseTab = Shuffleboard.getTab("Drivebase");
        driveBaseTab.add("Tank Drive", tankDrive);
        // Put both encoders in a list layout
        ShuffleboardLayout encoders =
                driveBaseTab.getLayout("Encoders", BuiltInLayouts.kList).withPosition(0, 0).withSize(2, 2);
        encoders.add("Left Encoder", leftEncoder);
        encoders.add("Right Encoder", rightEncoder);
        
        // Add the elevator motor and potentiometer to an 'Elevator' tab
        ShuffleboardTab elevatorTab = Shuffleboard.getTab("Elevator");
        elevatorTab.add("Motor", elevatorMotor);
        elevatorTab.add("Potentiometer", elevatorPot);
    }
    
    
    @Override
    public void autonomousInit()
    {
        // Read the value of the 'max speed' widget from the dashboard
        tankDrive.setMaxOutput(maxSpeed.getDouble(1.0));
    }
}
