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

package ${data.basePackage}.constants;

public final class ShooterConstants {
  public static final int HOOD_MOTOR_ID = 10;
  public static final int PRIMARY_SHOOTER_MOTOR_ID = 11;
  public static final int SECONDARY_SHOOTER_MOTOR_ID = 12;
  public static final int TERTIARY_SHOOTER_MOTOR_ID = 13;
  public static final int QUATERNARY_SHOOTER_MOTOR_ID = 14;

  public static final double HOOD_KP = 80;

  /** Example motor velocity feedforward constant, in volts per RPM. */
  public static final double EXAMPLE_MOTOR_KV = 12d / 6000d;

  /** Voltage necessary to break static friction to get the flywheel moving. */
  public static final double FLYWHEEL_KS = 1.25;

  public static final double FLYWHEEL_KP = 100;
}
