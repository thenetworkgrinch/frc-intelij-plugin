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

import edu.wpi.first.math.util.Units;



public class Constants
{
    public static final int MOTOR_PORT = 0;
    public static final int ENCODER_A_CHANNEL = 0;
    public static final int ENCODER_B_CHANNEL = 1;
    public static final int JOYSTICK_PORT = 0;
    
    public static final double ELEVATOR_KP = 5;
    public static final double ELEVATOR_KI = 0;
    public static final double ELEVATOR_KD = 0;
    
    public static final double ELEVATORK_S = 0.0; // volts (V)
    public static final double ELEVATORK_G = 0.762; // volts (V)
    public static final double ELEVATORK_V = 0.762; // volt per velocity (V/(m/s))
    public static final double ELEVATORK_A = 0.0; // volt per acceleration (V/(m/s²))
    
    public static final double ELEVATOR_GEARING = 10.0;
    public static final double ELEVATOR_DRUM_RADIUS = Units.inchesToMeters(2.0);
    public static final double CARRIAGE_MASS = 4.0; // kg
    
    public static final double SETPOINT_METERS = 0.75;
    // Encoder is reset to measure 0 at the bottom, so minimum height is 0.
    public static final double MIN_ELEVATOR_HEIGHT_METERS = 0.0;
    public static final double MAX_ELEVATOR_HEIGHT_METERS = 1.25;
    
    // distance per pulse = (distance per revolution) / (pulses per revolution)
    //  = (Pi * D) / ppr
    public static final double ELEVATOR_ENCODER_DIST_PER_PULSE =
            2.0 * Math.PI * ELEVATOR_DRUM_RADIUS / 4096;
}
