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

/**
 * The Constants class provides a convenient place for teams to hold robot-wide numerical or boolean
 * constants. This class should not be used for any other purpose. All constants should be declared
 * globally (i.e. public static). Do not put anything functional in this class.
 *
 * <p>It is advised to statically import this class (or one of its inner classes) wherever the
 * constants are needed, to reduce verbosity.
 */
public final class Constants {
  public static final class DriveConstants {
    public static final double DT = 0.02;
    public static final int LEFT_MOTOR1_PORT = 0;
    public static final int LEFT_MOTOR2_PORT = 1;
    public static final int RIGHT_MOTOR1_PORT = 2;
    public static final int RIGHT_MOTOR2_PORT = 3;

    // These are example values only - DO NOT USE THESE FOR YOUR OWN ROBOT!
    // These characterization values MUST be determined either experimentally or theoretically
    // for *your* robot's drive.
    // The SysId tool provides a convenient method for obtaining these values for your robot.
    public static final double ks = 1; // V
    public static final double kv = 0.8; // V/(m/s)
    public static final double ka = 0.15; // V/(m/s²)

    public static final double kp = 1;

    public static final double MAX_VELOCITY = 3; // m/s
    public static final double MAX_ACCELERATION = 3; // m/s²
  }

  public static final class OIConstants {
    public static final int DRIVER_CONTROLLER_PORT = 0;
  }
}
