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

package ${data.basePackage}.subsystems;

import edu.wpi.first.epilogue.Logged;
import edu.wpi.first.epilogue.NotLogged;
import edu.wpi.first.wpilibj.DigitalInput;
import ${data.basePackage}.Constants.StorageConstants;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;
import edu.wpi.first.wpilibj2.command.button.Trigger;



@Logged
public class Storage extends SubsystemBase
{
    private final PWMSparkMax motor = new PWMSparkMax(StorageConstants.MOTOR_PORT);
    @NotLogged // We'll log a more meaningful boolean instead
    private final DigitalInput ballSensor = new DigitalInput(StorageConstants.BALL_SENSOR_PORT);
    
    // Expose trigger from subsystem to improve readability and ease
    // inter-subsystem communications
    /** Whether the ball storage is full. */
    @Logged(name = "Has Cargo")
    @SuppressWarnings("checkstyle:MemberName")
    public final Trigger hasCargo = new Trigger(ballSensor::get);
    
    
    /** Create a new Storage subsystem. */
    public Storage()
    {
        // Set default command to turn off the storage motor and then idle
        setDefaultCommand(runOnce(motor::disable).andThen(run(() -> {})).withName("Idle"));
    }
    
    
    /** Returns a command that runs the storage motor indefinitely. */
    public Command runCommand()
    {
        return run(() -> motor.set(1)).withName("run");
    }
}
