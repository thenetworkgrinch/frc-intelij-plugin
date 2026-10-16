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

import edu.wpi.first.wpilibj.DoubleSolenoid;
import edu.wpi.first.wpilibj.PneumaticsModuleType;
import ${data.basePackage}.Constants.IntakeConstants;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



public class Intake implements AutoCloseable
{
    private final PWMSparkMax motor;
    private final DoubleSolenoid piston;
    
    
    public Intake()
    {
        motor = new PWMSparkMax(IntakeConstants.MOTOR_PORT);
        piston =
                new DoubleSolenoid(
                        PneumaticsModuleType.CTREPCM,
                        IntakeConstants.PISTON_FWD_CHANNEL,
                        IntakeConstants.PISTON_REV_CHANNEL);
    }
    
    
    public void deploy()
    {
        piston.set(DoubleSolenoid.Value.kForward);
    }
    
    
    public void retract()
    {
        piston.set(DoubleSolenoid.Value.kReverse);
        motor.set(0); // turn off the motor
    }
    
    
    public void activate(double speed)
    {
        if (isDeployed())
        {
            motor.set(speed);
        }
        else
        { // if piston isn't open, do nothing
            motor.set(0);
        }
    }
    
    
    public boolean isDeployed()
    {
        return piston.get() == DoubleSolenoid.Value.kForward;
    }
    
    
    @Override
    public void close()
    {
        piston.close();
        motor.close();
    }
}
