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

import ${data.basePackage}.subsystems.DriveSubsystem;
import edu.wpi.first.wpilibj2.command.Command;



public class DriveDistance extends Command
{
    private final DriveSubsystem drive;
    private final double distance;
    private final double speed;
    
    
    /**
     * Creates a new DriveDistance.
     *
     * @param inches The number of inches the robot will drive
     * @param speed  The speed at which the robot will drive
     * @param drive  The drive subsystem on which this command will run
     */
    public DriveDistance(double inches, double speed, DriveSubsystem drive)
    {
        distance = inches;
        this.speed = speed;
        this.drive = drive;
        addRequirements(this.drive);
    }
    
    
    @Override
    public void initialize()
    {
        drive.resetEncoders();
        drive.arcadeDrive(speed, 0);
    }
    
    
    @Override
    public void execute()
    {
        drive.arcadeDrive(speed, 0);
    }
    
    
    @Override
    public void end(boolean interrupted)
    {
        drive.arcadeDrive(0, 0);
    }
    
    
    @Override
    public boolean isFinished()
    {
        return Math.abs(drive.getAverageEncoderDistance()) >= distance;
    }
}
