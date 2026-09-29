public with sharing class NamedCredentialDependencyTest {
    public static HttpResponse makeTestCallout() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Test_Named_Credential');
        request.setMethod('GET');
        request.setTimeout(10000);
        return new Http().send(request);
    }
}