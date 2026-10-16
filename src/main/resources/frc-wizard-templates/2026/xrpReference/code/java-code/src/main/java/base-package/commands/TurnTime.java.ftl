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
import edu.wpi.first.wpilibj2.command.Command;



/*
 * Creates a new TurnTime command. This command will turn your robot for a
 * desired rotational speed and time.
 */
public class TurnTime extends Command
{
    private final double duration;
    private final double rotationalSpeed;
    private final Drivetrain drive;
    private long startTime;
    
    
    /**
     * Creates a new TurnTime.
     *
     * @param speed The speed which the robot will turn. Negative is in reverse.
     * @param time  How much time to turn in seconds
     * @param drive The drive subsystem on which this command will run
     */
    public TurnTime(double speed, double time, Drivetrain drive)
    {
        rotationalSpeed = speed;
        duration = time * 1000;
        this.drive = drive;
        addRequirements(drive);
    }
    
    
    // Called when the command is initially scheduled.
    @Override
    public void initialize()
    {
        startTime = System.currentTimeMillis();
        drive.arcadeDrive(0, 0);
    }
    
    
    // Called every time the scheduler runs while the command is scheduled.
    @Override
    public void execute()
    {
        drive.arcadeDrive(0, rotationalSpeed);
    }
    
    
    // Called once the command ends or is interrupted.
    @Override
    public void end(boolean interrupted)
    {
        drive.arcadeDrive(0, 0);
    }
    
    
    // Returns true when the command should end.
    @Override
    public boolean isFinished()
    {
        return (System.currentTimeMillis() - startTime) >= duration;
    }
}
