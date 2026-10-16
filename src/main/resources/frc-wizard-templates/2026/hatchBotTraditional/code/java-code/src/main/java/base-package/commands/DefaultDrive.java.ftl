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

package ${data.basePackage}.commands;

import java.util.function.DoubleSupplier;

import ${data.basePackage}.subsystems.DriveSubsystem;
import edu.wpi.first.wpilibj2.command.Command;



/**
 * A command to drive the robot with joystick input (passed in as {@link DoubleSupplier}s). Written
 * explicitly for pedagogical purposes - actual code should inline a command this simple with {@link
 * edu.wpi.first.wpilibj2.command.RunCommand}.
 */
public class DefaultDrive extends Command
{
    private final DriveSubsystem drive;
    private final DoubleSupplier forward;
    private final DoubleSupplier rotation;
    
    
    /**
     * Creates a new DefaultDrive.
     *
     * @param subsystem The drive subsystem this command wil run on.
     * @param forward   The control input for driving forwards/backwards
     * @param rotation  The control input for turning
     */
    public DefaultDrive(DriveSubsystem subsystem, DoubleSupplier forward, DoubleSupplier rotation)
    {
        drive = subsystem;
        this.forward = forward;
        this.rotation = rotation;
        addRequirements(drive);
    }
    
    
    @Override
    public void execute()
    {
        drive.arcadeDrive(forward.getAsDouble(), rotation.getAsDouble());
    }
}
