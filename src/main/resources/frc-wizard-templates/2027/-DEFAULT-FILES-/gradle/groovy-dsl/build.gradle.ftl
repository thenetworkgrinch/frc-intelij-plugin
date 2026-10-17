<#ftl output_format="plainText" encoding="UTF-8"> <#-- Output formats: https://freemarker.apache.org/docs/dgui_misc_autoescaping.html -->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--    
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>

<#if data.getIncludeKotlinSupport()>
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

</#if>
plugins {
    id "java"
    id "application"
<#if data.getIncludeKotlinSupport()>
    id "org.jetbrains.kotlin.jvm" version "${data.kotlinPluginVersion}"
    // kapt runs WPILib's annotation processors (such as Epilogue's) over the Kotlin and Java code
    id "org.jetbrains.kotlin.kapt" version "${data.kotlinPluginVersion}"
</#if>
    id "org.wpilib.GradleRIO" version "${data.wpilibVersion.versionString}"
    id "idea"
}

def javaVersion = JavaVersion.VERSION_25
<#if data.getIncludeKotlinSupport()>
def kotlinJvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.@Companion.fromTarget(javaVersion.toString())
</#if>

java {
    sourceCompatibility = javaVersion
    targetCompatibility = javaVersion
}

def ROBOT_MAIN_CLASS = "${data.mainClassFQ}"

<#if data.isSystemCoreRobotTemplate()>
// Define my targets (SystemCore) and artifacts (deployable files)
// This is added by GradleRIO's backing project DeployUtils.
deploy {
    targets {
        systemcore(getTargetTypeClass('SystemCore')) {
            // Team number is loaded either from the .wpilib/wpilib_preferences.json
            // or from command line. If not found an exception will be thrown.
            // You can use getTeamOrDefault(team) instead of getTeamNumber if you
            // want to store a team number in this file.
            team = project.wpilib.getTeamNumber()
            // Use the default systemcore host name. This must be called after setting team
            // as happens on the line above
            useDefaultSystemcoreHostName()
            debug = project.wpilib.getDebugOrDefault(false)

            artifacts {
                // First part is artifact name, 2nd is artifact type
                // getTargetTypeClass is a shortcut to get the class type using a string

                wpilibJava(getArtifactTypeClass('WPILibJavaArtifact')) {
                    // Set to true to use debug including JNI, which will drastically impact performance.
                    debugJni = false
                }

                // Static files artifact
                wpilibStaticFileDeploy(getArtifactTypeClass('FileTreeArtifact')) {
                    files = project.fileTree('src/main/deploy')
                    directory = '/home/systemcore/deploy'
                    deleteOldFiles = false // Change to true to delete files on systemcore that no
                                           // longer exist in deploy directory of this project
                }
            }
        }
    }
}

def deployArtifact = deploy.targets.systemcore.artifacts.wpilibJava

// Set to true to use debug for simulation including JNI
wpi.java.runSimWithDebugJni = false

</#if>
// Set this to true to enable desktop support.
//noinspection GroovyUnusedAssignment
def includeDesktopSupport = ${data.getIncludeDesktopSupportGradleSetting()}

// Defining my dependencies. In this case, WPILib (+ friends), and vendor libraries.
dependencies {
<#if data.getIncludeKotlinSupport()>
    kapt wpi.java.deps.wpilibAnnotations()
<#else>
    annotationProcessor wpi.java.deps.wpilibAnnotations()
</#if>
    implementation wpi.java.deps.wpilib()
    implementation wpi.java.vendor.java()
<#if data.isSystemCoreRobotTemplate()>

    systemcoreDebug wpi.java.deps.wpilibJniDebug(wpi.platforms.systemcore)
    systemcoreDebug wpi.java.vendor.jniDebug(wpi.platforms.systemcore)

    systemcoreRelease wpi.java.deps.wpilibJniRelease(wpi.platforms.systemcore)
    systemcoreRelease wpi.java.vendor.jniRelease(wpi.platforms.systemcore)
</#if>

    nativeDebug wpi.java.deps.wpilibJniDebug(wpi.platforms.desktop)
    nativeDebug wpi.java.vendor.jniDebug(wpi.platforms.desktop)
    simulationDebug wpi.sim.enableDebug()

    nativeRelease wpi.java.deps.wpilibJniRelease(wpi.platforms.desktop)
    nativeRelease wpi.java.vendor.jniRelease(wpi.platforms.desktop)
    simulationRelease wpi.sim.enableRelease()
<#if data.junitUseJUnitPlatform()>

    testImplementation platform("org.junit:junit-bom:${data.junit5Version}")
    testImplementation "org.junit.jupiter:junit-jupiter-api"
    testImplementation "org.junit.jupiter:junit-jupiter-params"
    testRuntimeOnly "org.junit.jupiter:junit-jupiter-engine"
    testRuntimeOnly "org.junit.platform:junit-platform-launcher"
</#if>
}

<#if data.junitUseJUnitPlatform()>
test {
    useJUnitPlatform()
    systemProperty 'junit.jupiter.extensions.autodetection.enabled', 'true'
}

</#if>
// Simulation configuration (e.g. environment variables).
wpi.sim.addGui().defaultEnabled = true
wpi.sim.addDriverstation()

<#if data.isRomiTemplate()>
//Sets the websocket client remote host.
wpi.sim.envVar("HALSIMWS_HOST", "10.0.0.2")
wpi.sim.addWebsocketsServer().defaultEnabled = true
wpi.sim.addWebsocketsClient().defaultEnabled = true

</#if>
<#if data.isXrpTemplate()>
//Sets the XRP Client Host
wpi.sim.envVar("HALSIMXRP_HOST", "192.168.42.1")
wpi.sim.addXRPClient().defaultEnabled = true

</#if>
application.mainClass = ROBOT_MAIN_CLASS

<#if data.isSystemCoreRobotTemplate()>
deployArtifact.configureApplication(application)
</#if>
wpi.java.configureApplication(application)
wpi.java.configureTestTasks(test)

<#if data.isSystemCoreRobotTemplate()>
// Include a backup of the project's source, vendordeps, and build file in the deployed jar
jar {
    from('src') { into 'backup/src' }
    from('vendordeps') { into 'backup/vendordeps' }
    from('build.gradle') { into 'backup' }
}

</#if>
tasks.withType(JavaCompile) {
    // Configure string concat to always inline compile
    options.compilerArgs.add '-XDstringConcat=inline'
}

<#if data.getIncludeKotlinSupport()>
kotlin {
    compilerOptions {
        jvmTarget.set(kotlinJvmTarget)
        // https://kotlinlang.org/docs/gradle-configure-project.html#gradle-java-toolchains-support
        jvmToolchain(Integer.valueOf(javaVersion.toString()))
    }
}
</#if>

idea {
    project {
        // The project.sourceCompatibility setting is not always picked up, so we set explicitly
        languageLevel = javaVersion
    }
    module {
        // Improve development & (especially) debugging experience (and IDEA's capabilities) by having libraries' source & javadoc attached
        downloadJavadoc = true
        downloadSources = true
        // Exclude the following from indexing and search
        excludeDirs+=file(".run" )
        excludeDirs+=file(".vscode" )
    }
}
