// scripts/priority.groovy


def flowFileList = session.get(1000)
if (flowFileList.isEmpty()) {
    return
}

def gotPriority1 = (flowFileList.get(0).getAttribute("priority").compareTo("A") == 0)

flowFileList.each { flowFile ->
    if (flowFile.getAttribute("priority").compareTo("A") == 0) {
        log.warn("PRIORITY {}", [flowFile.getAttribute("filename")] as Object[])
        session.transfer(flowFile, REL_SUCCESS)
    } else if (gotPriority1) {
        session.transfer(flowFile, REL_FAILURE)
    } else {
        log.warn("PRIORITY {}", [flowFile.getAttribute("filename")] as Object[])
        session.transfer(flowFile, REL_SUCCESS)
    }
}

