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

import edu.wpi.first.units.measure.Distance;
import edu.wpi.first.wpilibj.AddressableLED;
import edu.wpi.first.wpilibj.AddressableLEDBuffer;
import edu.wpi.first.wpilibj.LEDPattern;
import edu.wpi.first.wpilibj.TimedRobot;

import static edu.wpi.first.units.Units.Meters;
import static edu.wpi.first.units.Units.MetersPerSecond;



public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final AddressableLED led;
    private final AddressableLEDBuffer ledBuffer;
    
    // Create an LED pattern that will display a rainbow across
    // all hues at maximum saturation and half brightness
    private final LEDPattern rainbow = LEDPattern.rainbow(255, 128);
    
    // Our LED strip has a density of 120 LEDs per meter
    private static final Distance LED_SPACING = Meters.of(1 / 120.0);
    
    // Create a new pattern that scrolls the rainbow pattern across the LED strip, moving at a speed
    // of 1 meter per second.
    private final LEDPattern scrollingRainbow =
            rainbow.scrollAtAbsoluteSpeed(MetersPerSecond.of(1), LED_SPACING);
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        // PWM port 9
        // Must be a PWM header, not MXP or DIO
        led = new AddressableLED(9);
        
        // Reuse buffer
        // Default to a length of 60, start empty output
        // Length is expensive to set, so only set it once, then just update data
        ledBuffer = new AddressableLEDBuffer(60);
        led.setLength(ledBuffer.getLength());
        
        // Set the data
        led.setData(ledBuffer);
        led.start();
    }
    
    
    @Override
    public void robotPeriodic()
    {
        // Update the buffer with the rainbow animation
        scrollingRainbow.applyTo(ledBuffer);
        // Set the LEDs
        led.setData(ledBuffer);
    }
}
