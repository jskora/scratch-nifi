#!/usr/bin/groovy

def checkPom(currPom) {
    slurp = new XmlSlurper().parse(currPom)
    println "parent $slurp.parent.groupId, $slurp.parent.artifactId, $slurp.parent.version"
    println "parent $slurp.groupId, $slurp.artifactId, $slurp.version"
}

def findOut = new StringBuilder()
def findErr = new StringBuilder()

findPomProc = "find . -name pom.xml".execute()
findPomProc.consumeProcessOutput(findOut, findErr)
findPomProc.waitForOrKill(1000)

poms = 0
pomsPG = 0
pomsPA = 0
pomsPV = 0
pomsG = 0
pomsA = 0
pomsV = 0

findOut.eachLine() { pomPath, pomCount ->
    print "."
    pom = new XmlSlurper().parse(pomPath)
    poms += 1
    pomsPG += pom.parent.groupId != "" ? 1 : 0
    pomsPA += pom.parent.artifactId != "" ? 1 : 0
    pomsPV += pom.parent.version != "" ? 1 : 0
    pomsG += pom.groupId != "" ? 1 : 0
    pomsA += pom.artifactId != "" ? 1 : 0
    pomsV += pom.version != "" ? 1 : 0
}

println ""
println ""
println "poms=$poms pomsPG=$pomsPG pomsPA=$pomsPA pomsPV=$pomsPV pomsG=$pomsG pomsA=$pomsA pomsV=$pomsV"
