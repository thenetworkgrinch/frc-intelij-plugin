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

import edu.wpi.first.wpilibj.Joystick;
import edu.wpi.first.wpilibj.Relay;
import edu.wpi.first.wpilibj.TimedRobot;



/**
 * This is a sample program which uses joystick buttons to control a relay. A Relay (generally a
 * spike) has two outputs, each of which can be at either 0V or 12V and so can be used for actions
 * such as turning a motor off, full forwards, or full reverse, and is generally used on the
 * compressor. This program uses two buttons on a joystick and each button corresponds to one
 * output; pressing the button sets the output to 12V and releasing sets it to 0V.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final Joystick stick = new Joystick(0);
    private final Relay relay = new Relay(0);
    
    private static final int RELAY_FORWARD_BUTTON = 1;
    private static final int RELAY_REVERSE_BUTTON = 2;
    
    
    @Override
    public void teleopPeriodic()
    {
        /*
         * Retrieve the button values. GetRawButton will
         * return true if the button is pressed and false if not.
         */
        boolean forward = stick.getRawButton(RELAY_FORWARD_BUTTON);
        boolean reverse = stick.getRawButton(RELAY_REVERSE_BUTTON);
        
        /*
         * Depending on the button values, we want to use one of
         * kOn, kOff, kForward, or kReverse. kOn sets both outputs to 12V,
         * kOff sets both to 0V, kForward sets forward to 12V
         * and reverse to 0V, and kReverse sets reverse to 12V and forward to 0V.
         */
        if (forward && reverse)
        {
            relay.set(Relay.Value.kOn);
        }
        else if (forward)
        {
            relay.set(Relay.Value.kForward);
        }
        else if (reverse)
        {
            relay.set(Relay.Value.kReverse);
        }
        else
        {
            relay.set(Relay.Value.kOff);
        }
    }
}
