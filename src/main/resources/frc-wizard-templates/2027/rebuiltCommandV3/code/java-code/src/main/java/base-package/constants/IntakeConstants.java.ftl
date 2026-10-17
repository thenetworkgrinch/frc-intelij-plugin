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

import static org.wpilib.units.Units.Degrees;
import static org.wpilib.units.Units.RPM;

import org.wpilib.units.measure.Angle;
import org.wpilib.units.measure.AngularVelocity;

public final class IntakeConstants {
  public static final int ROLLER_MOTOR_ID = 20;
  public static final int WRIST_MOTOR_ID = 21;

  public static final Angle WRIST_STOW_ANGLE = Degrees.of(90);
  public static final Angle WRIST_DOWN_ANGLE = Degrees.of(-10);

  public static final Angle WRIST_AGITATE_UP = Degrees.of(10);
  public static final Angle WRIST_AGITATE_DOWN = WRIST_DOWN_ANGLE;

  public static final AngularVelocity ROLLER_INTAKE_SPEED = RPM.of(4000);
  public static final AngularVelocity ROLLER_EXPULSION_SPEED = RPM.of(-3500);
}
