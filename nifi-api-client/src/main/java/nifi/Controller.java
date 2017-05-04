package nifi;

import com.google.gson.JsonParser;
import com.google.gson.stream.JsonReader;

import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

public class Controller {

    private static final String test = "http://10.113.8.70:10080/nifi-api/controller";

    private URL restURL;

    public static void main(String[] args) throws IOException {
        Controller ctrl = new Controller(test);
        System.out.println(ctrl.root());
    }

    public Controller(String serverURL) throws MalformedURLException {
        this.restURL = new URL(serverURL);
    }

    public String root() throws IOException {
        HttpURLConnection conn = (HttpURLConnection) this.restURL.openConnection();
        conn.setRequestProperty("Accept", "application/json");
        if (conn.getResponseCode() == 200) {
            String data;
            try (InputStreamReader inStreamReader = new InputStreamReader(conn.getInputStream())) {
                data = new JsonParser().parse(new JsonReader(inStreamReader)).getAsString();
            }
            return data;
        } else {
            return conn.getResponseMessage();
        }
    }
}
