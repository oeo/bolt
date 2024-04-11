from http.server import HTTPServer, SimpleHTTPRequestHandler
import mimetypes

class WasmHTTPRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Ensure `.wasm` files are served with the correct MIME type
        if self.path.endswith('.wasm'):
            self.send_header('Content-Type', 'application/wasm')
        return super().end_headers()

if __name__ == '__main__':
    mimetypes.init()
    mimetypes.add_type('application/wasm', '.wasm')
    PORT = 8001
    httpd = HTTPServer(('localhost', PORT), WasmHTTPRequestHandler)
    print(f"Serving at port {PORT}")
    httpd.serve_forever()

