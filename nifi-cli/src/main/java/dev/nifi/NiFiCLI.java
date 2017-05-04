package dev.nifi;


import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.nifi.client.ApiClient;
import org.apache.nifi.client.ApiException;
import org.apache.nifi.client.api.ProcessGroupsApi;
import org.apache.nifi.client.api.ProcessorsApi;
import org.apache.nifi_client.model.ProcessGroupEntity;

import java.util.Scanner;

public class NiFiCLI {

    private final Options options;
    private final CommandLineParser parser;
    private final CommandLine commandLine;
    private final ApiClient apiClient;

    private ProcessGroupEntity rootProcessGroup = null;

    public static void main(String[] args) {
        try {
            NiFiCLI cli = new NiFiCLI(args);
            cli.run();
        } catch (ParseException e) {
            e.printStackTrace();
        }
    }

    public NiFiCLI(String[] args) throws ParseException {
        options = new Options();
        options.addOption(Option.builder("url").hasArg(true).desc("URL of NiFi instance").required(true).build());

        parser = new DefaultParser();

        commandLine = parser.parse(options, args);

        apiClient = new ApiClient();
        apiClient.setBasePath(options.getOption("url").getValue());
    }

    public void run() {
        Scanner scanner = new Scanner(System.in);

        while (true) {
            String command = scanner.next();
            switch (command) {
                case "processors":
                    processors();
                    break;
                default:
                    throw new RuntimeException("unexpected command \"" + command + "\"");
            }
        }
    }

    private void processors() {
        try {
            ProcessGroupsApi processGroupsApi = new ProcessGroupsApi(apiClient);
            rootProcessGroup = processGroupsApi.getProcessGroup("root");
            if (rootProcessGroup != null) {
                ProcessorsApi processorsApi = new ProcessorsApi(apiClient);

            }
        } catch (ApiException e) {
            e.printStackTrace();
        }
    }
}
