# gcp-gke/02-modules/06-app-deploy/templates/sync_jenkins.py

def main():
    if len(sys.argv) < 3:
        print("Error: Missing arguments. Usage: python3 sync_jenkins.py <job_name> <xml_path>")
        sys.exit(1)

    job_name = sys.argv[1]
    xml_path = sys.argv[2]
    
    jenkins_url = os.environ.get("JENKINS_URL", "http://localhost:8080")
    user = "admin"

    # Fetch admin password from k8s secret
    pass_cmd = subprocess.run(
        ["kubectl", "get", "secret", "jenkins", "-n", "jenkins", "-o", "jsonpath={.data.jenkins-admin-password}"],
        capture_output=True, text=True
    )
    if pass_cmd.returncode != 0:
        print(f"Error: Failed to fetch Jenkins secret from Kubernetes: {pass_cmd.stderr}")
        sys.exit(1)
        
    password = base64.b64decode(pass_cmd.stdout.strip()).decode('utf-8')

    # Set up a cookie jar to maintain session cookies across requests
    cookie_jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookie_jar))
    urllib.request.install_opener(opener)

    def make_request(url, data=None, headers={}, allow_404=False):
        req = urllib.request.Request(url, data=data, headers=headers, method="POST" if data else "GET")
        auth = base64.b64encode(f"{user}:{password}".encode()).decode()
        req.add_header("Authorization", f"Basic {auth}")
        try:
            with urllib.request.urlopen(req) as response:
                return response.read()
        except urllib.error.HTTPError as e:
            if allow_404 and e.code == 404:
                return None
            print(f"HTTP Error calling {url}: {e.code} {e.reason}")
            try:
                err_body = e.read().decode('utf-8')
                print(f"Response body: {err_body}")
            except:
                pass
            sys.exit(1)
        except urllib.error.URLError as e:
            print(f"Network Error connecting to Jenkins at {url}: {e.reason}")
            sys.exit(1)

    # Get crumb token for CSRF protection
    headers = {'Content-Type': 'application/xml'}
    crumb_res = make_request(f"{jenkins_url}/crumbIssuer/api/json", allow_404=True)
    if crumb_res:
        try:
            crumb_data = json.loads(crumb_res.decode())
            headers[crumb_data['crumbRequestField']] = crumb_data['crumb']
        except Exception:
            pass

    # --- HANDLE DELETION ON TERRAFORM DESTROY ---
    if len(sys.argv) > 3 and sys.argv[3] == "delete":
        # Jenkins delete endpoint requires POST with headers/crumb
        make_request(f"{jenkins_url}/job/{job_name}/doDelete", data=b"", headers=headers, allow_404=True)
        print(f"Successfully deleted Jenkins job: {job_name}")
        sys.exit(0)
    # ---------------------------------------------