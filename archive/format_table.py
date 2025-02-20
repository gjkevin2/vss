labels = '''\
<table><thead><tr><th colspan="2">材料种类</th><th>密度(g/cm3)</th><th>抗拉强度/MPa</th><th>弹性模量MPa</th><th>比强度</th><th>比模量</th><th>耐腐蚀性</th></tr></thead><tbody><tr><td colspan="2">高强度钢</td><td>7.8</td><td>1000</td><td>214000</td><td>1.3</td><td>0.27</td><td>一般</td></tr><tr><td colspan="2">铝合金</td><td>2.8</td><td>420</td><td>71000</td><td>1.5</td><td>0.25</td><td>较强</td></tr><tr><td colspan="2">镁合金</td><td>1.79</td><td>280</td><td>45000</td><td>1.6</td><td>0.25</td><td>差</td></tr><tr><td colspan="2">钛合金</td><td>4.5</td><td>942</td><td>112000</td><td>2.1</td><td>0.25</td><td>强</td></tr><tr><td colspan="2">玻璃纤维复合材料</td><td>2.0</td><td>1100</td><td>40000</td><td>5.5</td><td>0.2</td><td>强</td></tr><tr><td rowspan="2">碳纤维复合材料</td><td>高强度型</td><td>1.5</td><td>1400</td><td>130000</td><td>9.3</td><td>0.87</td><td>非常强</td></tr><tr><td>低强度型</td><td>1.6</td><td>1100</td><td>190000</td><td>6.2</td><td>1.2</td><td>非常强</td></tr></tbody></table>
'''

captionstr = '表1 各类汽车轻量化材料力学特性对比'

if captionstr:
    captioncode = '\n\t<caption>' + captionstr + '</caption>'
    labels = labels.replace('<table>', '<table>' + captioncode)

finalstr = '<div align="center">\n' + labels.replace('<thead>', '\n\t<thead>').replace('</thead>', '\n\t</thead>').replace('<tbody>', '\n\t<tbody>').replace('</tbody>', '\n\t</tbody>').replace('<tr>', '\n\t\t<tr>').replace('</table>', '\n</table>') + '</div>'

print(finalstr)