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

import ${data.basePackage}.subsystems.Drivetrain;
import edu.wpi.first.wpilibj2.command.SequentialCommandGroup;



public class AutonomousDistance extends SequentialCommandGroup
{
    /**
     * Creates a new Autonomous Drive based on distance. This will drive out for a specified distance,
     * turn around and drive back.
     *
     * @param drivetrain The drivetrain subsystem on which this command will run
     */
    public AutonomousDistance(Drivetrain drivetrain)
    {
        addCommands(
                new DriveDistance(-0.5, 10, drivetrain),
                new TurnDegrees(-0.5, 180, drivetrain),
                new DriveDistance(-0.5, 10, drivetrain),
                new TurnDegrees(0.5, 180, drivetrain));
    }
}
