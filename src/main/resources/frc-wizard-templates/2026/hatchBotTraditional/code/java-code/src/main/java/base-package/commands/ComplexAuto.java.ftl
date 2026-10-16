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

import ${data.basePackage}.Constants.AutoConstants;
import ${data.basePackage}.subsystems.DriveSubsystem;
import ${data.basePackage}.subsystems.HatchSubsystem;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;



/** A complex auto command that drives forward, releases a hatch, and then drives backward. */
public class ComplexAuto extends SequentialCommandGroup
{
    /**
     * Creates a new ComplexAuto.
     *
     * @param drive The drive subsystem this command will run on
     * @param hatch The hatch subsystem this command will run on
     */
    public ComplexAuto(DriveSubsystem drive, HatchSubsystem hatch)
    {
        addCommands(
                // Drive forward the specified distance
                new DriveDistance(
                        AutoConstants.AUTO_DRIVE_DISTANCE_INCHES, AutoConstants.AUTO_DRIVE_SPEED, drive),
                
                // Release the hatch
                new ReleaseHatch(hatch),
                
                // Drive backward the specified distance
                new DriveDistance(
                        AutoConstants.AUTO_BACKUP_DISTANCE_INCHES, -AutoConstants.AUTO_DRIVE_SPEED, drive));
    }
}
