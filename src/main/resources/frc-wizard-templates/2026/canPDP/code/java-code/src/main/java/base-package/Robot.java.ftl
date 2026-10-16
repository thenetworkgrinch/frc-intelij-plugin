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

import edu.wpi.first.wpilibj.PowerDistribution;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;



/**
 * This is a sample program showing how to retrieve information from the Power Distribution Panel
 * via CAN. The information will be displayed under variables through the SmartDashboard.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final PowerDistribution pdp = new PowerDistribution();
    
    
    public Robot()
    {
        // Put the PDP itself to the dashboard
        SmartDashboard.putData("PDP", pdp);
    }
    
    
    @Override
    public void robotPeriodic()
    {
        // Get the current going through channel 7, in Amperes.
        // The PDP returns the current in increments of 0.125A.
        // At low currents the current readings tend to be less accurate.
        double current7 = pdp.getCurrent(7);
        SmartDashboard.putNumber("Current Channel 7", current7);
        
        // Get the voltage going into the PDP, in Volts.
        // The PDP returns the voltage in increments of 0.05 Volts.
        double voltage = pdp.getVoltage();
        SmartDashboard.putNumber("Voltage", voltage);
        
        // Retrieves the temperature of the PDP, in degrees Celsius.
        double temperatureCelsius = pdp.getTemperature();
        SmartDashboard.putNumber("Temperature", temperatureCelsius);
        
        // Get the total current of all channels.
        double totalCurrent = pdp.getTotalCurrent();
        SmartDashboard.putNumber("Total Current", totalCurrent);
        
        // Get the total power of all channels.
        // Power is the bus voltage multiplied by the current with the units Watts.
        double totalPower = pdp.getTotalPower();
        SmartDashboard.putNumber("Total Power", totalPower);
        
        // Get the total energy of all channels.
        // Energy is the power summed over time with units Joules.
        double totalEnergy = pdp.getTotalEnergy();
        SmartDashboard.putNumber("Total Energy", totalEnergy);
    }
}
