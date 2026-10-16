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
<#if data.getIncludeKotlinSupport()>
    id "org.jetbrains.kotlin.jvm" version "${data.kotlinVersion}"
</#if>
    id "edu.wpi.first.GradleRIO" version "${data.wpilibVersion.versionString}"
    id "idea"
}

def javaVersion = JavaVersion.VERSION_17
<#if data.getIncludeKotlinSupport()>
def kotlinJvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.@Companion.fromTarget(javaVersion.toString())
</#if>

java {
    sourceCompatibility = javaVersion
    targetCompatibility = javaVersion
}

def ROBOT_MAIN_CLASS = "${data.mainClassFQ}"

<#if data.isRoboRioRobotTemplate()>
// Define my targets (RoboRIO) and artifacts (deployable files)
// This is added by GradleRIO's backing project DeployUtils.
deploy {
    targets {
        roborio(getTargetTypeClass('RoboRIO')) {
            // Team number is loaded either from the .wpilib/wpilib_preferences.json
            // or from command line. If not found an exception will be thrown.
            // You can use getTeamOrDefault(team) instead of getTeamNumber if you
            // want to store a team number in this file.
            team = project.frc.getTeamNumber()
            debug = project.frc.getDebugOrDefault(false)

            artifacts {
                // First part is artifact name, 2nd is artifact type
                // getTargetTypeClass is a shortcut to get the class type using a string

                frcJava(getArtifactTypeClass('FRCJavaArtifact')) {
                }

                // Static files artifact
                frcStaticFileDeploy(getArtifactTypeClass('FileTreeArtifact')) {
                    files = project.fileTree('src/main/deploy')
                    directory = '/home/lvuser/deploy'
                    deleteOldFiles = false // Change to true to delete files on roboRIO that no
                                           // longer exist in deploy directory of this project
                }
            }
        }
    }
}

def deployArtifact = deploy.targets.roborio.artifacts.frcJava

// Set to true to use debug for all targets including JNI, which will drastically impact
// performance.
wpi.java.debugJni = false
</#if>

// Set this to true to enable desktop support.
//noinspection GroovyUnusedAssignment
def includeDesktopSupport = ${data.getIncludeDesktopSupportGradleSetting()}

dependencies {
    annotationProcessor wpi.java.deps.wpilibAnnotations()
    implementation wpi.java.deps.wpilib()
    implementation wpi.java.vendor.java()
<#if data.isRoboRioRobotTemplate()>

    roborioDebug wpi.java.deps.wpilibJniDebug(wpi.platforms.roborio)
    roborioDebug wpi.java.vendor.jniDebug(wpi.platforms.roborio)

    roborioRelease wpi.java.deps.wpilibJniRelease(wpi.platforms.roborio)
    roborioRelease wpi.java.vendor.jniRelease(wpi.platforms.roborio)
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
</#if>
}

<#if data.junitUseJUnitPlatform()>
test{
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
// Setting up my Jar File. In this case, adding all libraries into the main jar ('fat jar')
// in order to make them all available at runtime. Also adding the manifest so WPILib
// knows where to look for our Robot Class.
jar {
    from { configurations.runtimeClasspath.collect { it.isDirectory() ? it : zipTree(it) } }
    <#if data.isRoboRioRobotTemplate()>
    from('src') { into 'backup/src' }
    from('vendordeps') { into 'backup/vendordeps' }
    from('build.gradle') { into 'backup' }
    </#if>
    manifest edu.wpi.first.gradlerio.GradleRIOPlugin.javaManifest(ROBOT_MAIN_CLASS)
    duplicatesStrategy = DuplicatesStrategy.INCLUDE
}

<#if data.isRoboRioRobotTemplate()>
// Configure jar and deploy tasks
deployArtifact.jarTask = jar
</#if>
wpi.java.configureExecutableTasks(jar)
wpi.java.configureTestTasks(test)

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