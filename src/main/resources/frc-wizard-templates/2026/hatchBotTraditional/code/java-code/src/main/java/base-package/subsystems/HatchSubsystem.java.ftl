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

import edu.wpi.first.util.sendable.SendableBuilder;
import edu.wpi.first.wpilibj.DoubleSolenoid;
import edu.wpi.first.wpilibj.PneumaticsModuleType;
import ${data.basePackage}.Constants.HatchConstants;
import edu.wpi.first.wpilibj2.command.SubsystemBase;

import static edu.wpi.first.wpilibj.DoubleSolenoid.Value.kForward;
import static edu.wpi.first.wpilibj.DoubleSolenoid.Value.kReverse;



/** A hatch mechanism actuated by a single {@link DoubleSolenoid}. */
public class HatchSubsystem extends SubsystemBase
{
    private final DoubleSolenoid hatchSolenoid =
            new DoubleSolenoid(
                    PneumaticsModuleType.CTREPCM,
                    HatchConstants.HATCH_SOLENOID_PORTS[0],
                    HatchConstants.HATCH_SOLENOID_PORTS[1]);
    
    
    /** Grabs the hatch. */
    public void grabHatch()
    {
        hatchSolenoid.set(kForward);
    }
    
    
    /** Releases the hatch. */
    public void releaseHatch()
    {
        hatchSolenoid.set(kReverse);
    }
    
    
    @Override
    public void initSendable(SendableBuilder builder)
    {
        super.initSendable(builder);
        // Publish the solenoid state to telemetry.
        builder.addBooleanProperty("extended", () -> hatchSolenoid.get() == kForward, null);
    }
}
