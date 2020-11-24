import { group, sleep } from 'k6';
import http from 'k6/http';

// Version: 1.2
// Creator: WebInspector

export let options = {
	maxRedirects: 0,
	stages: [
		// {
		// 	target : 50, duration : "30s"
		// },
		// {
		// 	target: 200, duration : "1m"
		// },
		// {
		// 	target : 100, duration : "30s"
		// },
		// {
		// 	target : 100, duration : "10s"
		// },
		// {
		// 	target : 200, duration : "20s"
		// },
		// {
		// 	target : 300, duration : "30s"
		// }
		{
			target : 400, duration : "10s"
		}
		]
};

export default function() {

	group("page_13 - http://localhost:8000/", function() {
		let req, res;
		req = [{
			"method": "post",
			"url": "http://localhost:3000/comment/add",
			"body": "{\"id\":\"03d8d5ec0b7c98329749\",\"username\":\"ramang\",\"content\":\"kapp\"}",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Content-Type": "application/json",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		}];
		res = http.batch(req);
		// Random sleep between 20s and 40s
		sleep(Math.floor(Math.random()*20+20));
	});

}
