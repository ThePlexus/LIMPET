# LIMPET
### Latency Insight Monitor for Performance Evaluation & Testing

### What is LIMPET?
A simple one shot system to measure your network uplink using Ping, HTTP and 
[networkquality-rs](https://github.com/cloudflare/networkquality-rs/).
The output is collated via telegraf and exportable on port 9100 for consumption 
by prometheus. 

### Connection Speed, Jitter and RPM recording
[networkquality-rs](https://github.com/cloudflare/networkquality-rs/) is a rust 
tool which can measure the download speed, upload speed and jitter performance 
of your connection, based on [Responsiveness under working conditions]
(https://datatracker.ietf.org/doc/draft-ietf-ippm-responsiveness/). We use this
tool which runs every 4 hours and records the upload, download speed, jitter
and RPM 

RPM is Roundtrips Per Minute. The higher your RPM, the better. 

The collector persists the data of the last true run so each scrape by 
prometheus will always receive the data from the last run of the test.


The metrics you want to look at are 
```
mach_speedtest_download_throughput_mbps
mach_speedtest_upload_throughput_mbps
mach_speedtest_jitter_ms
mach_speedtest_download_rpm
mach_speedtest_upload_rpm

```


### Ping Check
To measure path loss and RTT ping time, pings are made to Cloudflares 
DNS servers over IPv4 and IPv6
```
1.1.1.1
1.0.0.1
2606:4700:4700::1111
2606:4700:4700::1001
```
Every minute, we run four pings to each host with a 0.5s interval between 
each ping, so four pings in 2 seconds total. There is a 2 second timeout

The exported metrics are;

```
ping_average_response_ms
ping_percent_packet_loss
```

### DNS check
Every minute a DNS responsiveness check is made to 4 Cloudflare DNS servers
```
1.1.1.1
1.0.0.1
2606:4700:4700::1111
2606:4700:4700::1001
```
This will lookup 'www.cloudflare.com' and return the ms time for the entire 
lookup

The exported metric is 
```
dns_query_query_time_ms
```

### HTTP check
Every minute we run a HTTP GET to https://www.cloudflare.com and measure the 
response. 

The exported metrics is 

```
http_response_response_time
```


### Running
The container is plug n play. Spin it up, then point prometheus at it on 
port 9100.


```
docker run --name=limpet \
	-p 9100:9100 \
	--restart unless-stopped \
	limpet
```

That should be all you need to do and its now monitoring the above parameters.

### using your own config
If you want to ping or web responsive test other hosts, dimply create your own 
telegraf.conf and set it when launching the container

```
	-v /path/to/telegraf.conf:/etc/telegraf/telegraf.conf:ro 
```

### Network Quality endpoints
You can use different endpoints for the networkquality-rs tests. Pass them in as
env vars. Query string API key authentication is supported

```	
	-e "LARGEFILE=https://your.server/your.large.file" \
	-e "SMALLFILE=https://your.server/your.small.file" \
	-e "UPLOADEP=https://your.server/your.uploads.endpoint" \
```
You can read more about [making your own server]
(https://github.com/network-quality/server)

### Speed test interval
By default, the test runs once every 240 minutes / 4 hours.
You can modify the interval the  speed test runs at. It defaults 
to every 240 minutes / 4 hours,  but you can make it more frequent 
by setting the time between runs, in minutes. You probably don't 
need this lower than 60, your line conditions are better 
monitored via ping and responsiveness tests, the bandwidth is 
unlikely to change frequently.

```
	-e "MACH_INTERVAL=60" \
```
