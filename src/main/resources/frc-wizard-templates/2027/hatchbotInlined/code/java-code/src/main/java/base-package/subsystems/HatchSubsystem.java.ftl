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

import static org.wpilib.hardware.pneumatic.DoubleSolenoid.Value.FORWARD;
import static org.wpilib.hardware.pneumatic.DoubleSolenoid.Value.REVERSE;

import org.wpilib.command2.Command;
import org.wpilib.command2.SubsystemBase;
import ${data.basePackage}.Constants.HatchConstants;
import org.wpilib.hardware.bus.CANPort;
import org.wpilib.hardware.pneumatic.DoubleSolenoid;
import org.wpilib.hardware.pneumatic.PneumaticsModuleType;
import org.wpilib.telemetry.TelemetryTable;

/** A hatch mechanism actuated by a single {@link org.wpilib.hardware.pneumatic.DoubleSolenoid}. */
public class HatchSubsystem extends SubsystemBase {
  private final DoubleSolenoid hatchSolenoid =
      new DoubleSolenoid(
          CANPort.CAN_S0,
          PneumaticsModuleType.CTRE_PCM,
          HatchConstants.HATCH_SOLENOID_PORTS[0],
          HatchConstants.HATCH_SOLENOID_PORTS[1]);

  /** Grabs the hatch. */
  public Command grabHatchCommand() {
    // implicitly require `this`
    return this.runOnce(() -> hatchSolenoid.set(FORWARD));
  }

  /** Releases the hatch. */
  public Command releaseHatchCommand() {
    // implicitly require `this`
    return this.runOnce(() -> hatchSolenoid.set(REVERSE));
  }

  @Override
  public void logTo(TelemetryTable table) {
    super.logTo(table);
    // Publish the solenoid state to telemetry.
    table.log("extended", hatchSolenoid.get() == FORWARD);
  }
}
