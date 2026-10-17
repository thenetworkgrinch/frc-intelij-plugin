<#ftl output_format="plainText" encoding="UTF-8"> <#-- Output formats: https://freemarker.apache.org/docs/dgui_misc_autoescaping.html -->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--    
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
import org.gradle.internal.os.OperatingSystem

pluginManagement {
    repositories {
        String wpilibYear = '${data.projectYear}'
        File wpilibHome
        def os = OperatingSystem.current()
        if (os.isWindows()) {
            String publicFolder = System.getenv('PUBLIC')
            if (publicFolder == null) {
                publicFolder = "C:\\Users\\Public"
            }
            def homeRoot = new File(publicFolder, "wpilib")
            wpilibHome = new File(homeRoot, wpilibYear)
        } else if (os.isLinux()) {
            String xdgDataHome = System.getenv('XDG_DATA_HOME')
            if (xdgDataHome == null || xdgDataHome.trim().isEmpty() || !new File(xdgDataHome).isAbsolute()) {
                xdgDataHome = new File(System.getProperty("user.home"), ".local/share").getPath()
            }
            def homeRoot = new File(xdgDataHome, "wpilib")
            wpilibHome = new File(homeRoot, wpilibYear)
        } else {
            def userFolder = System.getProperty("user.home")
            def homeRoot = new File(userFolder, ".wpilib")
            wpilibHome = new File(homeRoot, wpilibYear)
        }
        def wpilibHomeMaven = new File(wpilibHome, 'maven')
        maven {
            name = 'wpilibHome'
            url = wpilibHomeMaven
        }
        mavenLocal()
        gradlePluginPortal()
    }
}

Properties props = System.getProperties();
props.setProperty("org.gradle.internal.native.headers.unresolved.dependencies.ignore", "true");
