package jskora.nifi;

import org.apache.nifi.flowfile.FlowFile;
import org.apache.nifi.provenance.ProvenanceEventType;
import org.apache.nifi.provenance.StandardProvenanceEventRecord;
import org.apache.nifi.provenance.serialization.RecordWriter;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class WriterBenchmark {

    private static String JOURNAL_PATH = "/tmp/journal.tmp";
    private RecordWriter writer;
    private StandardProvenanceEventRecord record;
    private long eventId = 10001;

    private static int NUM_RECORDS = 1000;

    public static void main( String[] args ) throws IOException {
        WriterBenchmark benchmark = new WriterBenchmark();
        benchmark.run();
        benchmark.close();
    }

    public WriterBenchmark() throws IOException {
        final Map<String, String> attributes = new HashMap<>();
        attributes.put("uuid", "12345678-0000-0000-0000-012345678912");
        final FlowFile flowFile = createFlowFile(3L, 3000L, attributes);

        writer = new TestWriter_original(new File(JOURNAL_PATH), null, false, 1048576);
        writer.writeHeader(eventId++);

        record = (StandardProvenanceEventRecord) new StandardProvenanceEventRecord.Builder()
                .setEventTime(System.currentTimeMillis())
                .setEventType(ProvenanceEventType.RECEIVE)
                .setTransitUri("nifi://unit-test")
                .fromFlowFile(flowFile)
                .setComponentId("1234")
                .setComponentType("dummy processor")
                .build();
    }

    public void run() throws IOException {
        for (int i = 0; i < NUM_RECORDS; i++) {
            writer.writeRecord(record, eventId++);
        }
    }

    public void close() throws IOException {
        writer.close();
    }

    public static FlowFile createFlowFile(final long id, final long fileSize, final Map<String, String> attributes) {
        final Map<String, String> attrCopy = new HashMap<>(attributes);

        return new FlowFile() {
            @Override
            public long getId() {
                return id;
            }

            @Override
            public long getEntryDate() {
                return System.currentTimeMillis();
            }

            @Override
            public long getLineageStartDate() {
                return System.currentTimeMillis();
            }

            @Override
            public Long getLastQueueDate() {
                return System.currentTimeMillis();
            }

            @Override
            public boolean isPenalized() {
                return false;
            }

            @Override
            public String getAttribute(final String s) {
                return attrCopy.get(s);
            }

            @Override
            public long getSize() {
                return fileSize;
            }

            @Override
            public Map<String, String> getAttributes() {
                return attrCopy;
            }

            @Override
            public int compareTo(final FlowFile o) {
                return 0;
            }

            @Override
            public long getLineageStartIndex() {
                return 0;
            }

            @Override
            public long getQueueDateIndex() {
                return 0;
            }
        };
    }
}
