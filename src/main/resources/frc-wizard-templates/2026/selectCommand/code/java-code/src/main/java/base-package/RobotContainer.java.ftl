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

import java.util.Map;

import edu.wpi.first.wpilibj.GenericHID;
import edu.wpi.first.wpilibj.XboxController;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.PrintCommand;
import edu.wpi.first.wpilibj2.command.SelectCommand;



/**
 * This class is where the bulk of the robot should be declared. Since Command-based is a
 * "declarative" paradigm, very little robot logic should actually be handled in the {@link Robot}
 * periodic methods (other than the scheduler calls). Instead, the structure of the robot (including
 * subsystems, commands, and button mappings) should be declared here.
 */
public class RobotContainer
{
    // The enum used as keys for selecting the command to run.
    private enum CommandSelector
    {
        ONE,
        TWO,
        THREE
    }
    
    
    // An example selector method for the SelectCommand  Returns the selector that will select
    // which command to run.  Can base this choice on logical conditions evaluated at runtime.
    private CommandSelector select()
    {
        return CommandSelector.ONE;
    }
    
    
    // An example SelectCommand  Will select from the three commands based on the value returned
    // by the selector method at runtime.  Note that selectcommand works on Object(), so the
    // selector does not have to be an enum; it could be any desired type (string, integer,
    // boolean, double...)
    private final Command exampleSelectCommand =
            new SelectCommand<>(
                    // Maps selector values to commands
                    Map.ofEntries(
                            Map.entry(CommandSelector.ONE, new PrintCommand("Command one was selected!")),
                            Map.entry(CommandSelector.TWO, new PrintCommand("Command two was selected!")),
                            Map.entry(CommandSelector.THREE, new PrintCommand("Command three was selected!"))),
                    this::select);
    
    
    public RobotContainer()
    {
        // Configure the button bindings
        configureButtonBindings();
    }
    
    
    /**
     * Use this method to define your button->command mappings. Buttons can be created by
     * instantiating a {@link GenericHID} or one of its subclasses ({@link
     * edu.wpi.first.wpilibj.Joystick} or {@link XboxController}), and then calling passing it to a
     * {@link edu.wpi.first.wpilibj2.command.button.JoystickButton}.
     */
    private void configureButtonBindings() {}
    
    
    /**
     * Use this to pass the autonomous command to the main {@link Robot} class.
     *
     * @return the command to run in autonomous
     */
    public Command getAutonomousCommand()
    {
        return exampleSelectCommand;
    }
}
